;; ref: wasi:cli/run@0.2.0
;; 
;; interface run {
;;   run: func() -> result;
;; }

;; ref: wasi:cli/stdout@0.2.0
;;
;; interface stdout {
;;   use wasi:io/streams@0.2.2.{output-stream};
;; 
;;   get-stdout: func() -> output-stream;
;; }

;; ref: wasi:io/streams@0.2.2.{output-stream}
;; 
;; variant stream-error {
;;     last-operation-failed(error),
;;     closed
;; }
;; 
;; resource output-stream {
;;     check-write: func() -> result<u64, stream-error>;
;;
;;     write: func(contents: list<u8>) -> result<_, stream-error>;
;; 
;;     blocking-write-and-flush: func(contents: list<u8>) -> result<_, stream-error>;
;; 
;;     flush: func() -> result<_, stream-error>;
;; 
;;     blocking-flush: func() -> result<_, stream-error>;
;; 
;;     subscribe: func() -> pollable;
;; 
;;     write-zeroes: func(len: u64) -> result<_, stream-error>;
;; 
;;     blocking-write-zeroes-and-flush: func(len: u64) -> result<_, stream-error>;
;; 
;;     splice: func(src: borrow<input-stream>, len: u64) -> result<u64, stream-error>;
;; 
;;     blocking-splice: func(src: borrow<input-stream>, len: u64) -> result<u64, stream-error>;
;; }

(component
    ;; wasi:io/error@0.2.0
    (import "wasi:io/error@0.2.0" (instance $error
        ;; resource
        (export $error "error" (type (sub resource)))
    ))
    (alias export $error "error" (type $error))

    ;; wasi:io/streams@0.2.2
    (import "wasi:io/streams@0.2.2" (instance $streams
        ;; dependency
        (alias outer 1 $error (type $error))

        ;; struct
        (type $.stream-error (variant (case "last-operation-failed" (own $error)) (case "closed")))
        (export $stream-error "stream-error" (type (eq $.stream-error)))

        ;; resource
        (export $output-stream "output-stream" (type (sub resource)))
        (export $output-stream.blocking-write-and-flush "[method]output-stream.blocking-write-and-flush"
            (func (param "self" (borrow $output-stream)) (param "contents" (list u8)) (result (result (error $stream-error))))
        )
    ))
    (alias export $streams "output-stream" (type $output-stream))
    ;; (core func $core_func_output-stream.blocking-write-and-flush
    ;;     (canon lower ())
    ;; )
    ;; (core instance $core_instance.streams
    ;;     (export "output-stream.blocking-write-and-flush" (func $core_func_output-stream.blocking-write-and-flush))
    ;; )

    ;; wasi:cli/stdout@0.2.0
    (import "wasi:cli/stdout@0.2.0" (instance $stdout
        (export "get-stdout" (func (result (own $output-stream))))
    ))
    (core func $core_func.get-stdout
        (canon lower (func $stdout "get-stdout"))
    )
    (core instance $core_instance.stdout
        (export "get-stdout" (func $core_func.get-stdout))
    )

    ;; lift core func to component func via core module/instance
    (core module $core_module
        (import "wasi:cli/stdout@0.2.0" "get-stdout" (func $get-stdout (result i32)))
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        (func (export "main") (result i32)
            ;;call $get-stdout
            (i32.const 0)
        )
    )
    (core instance $core_instance (instantiate $core_module
        (with "wasi:cli/stdout@0.2.0" (instance $core_instance.stdout))
    ))
    (func $main (result (result))
        (canon lift (core func $core_instance "main"))
    )
    
    ;; construct component with the lifted component func
    (component $my_component
        (import "bridge" (func $hoge (result (result))))
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        (export "run" (func $hoge))
    )
    (instance $my_instance (instantiate $my_component
        (with "bridge" (func $main))
    ))

    ;; export instance of expected interface e.g. wasi:cli/run
    (export "wasi:cli/run@0.2.0" (instance $my_instance))
)
