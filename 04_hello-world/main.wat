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
    (core module $root
        (memory $memory 17)
        (export "memory" (memory $memory))
    )
    (core instance $root (instantiate $root))
    (alias core export $root "memory" (core memory $M))

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
    (core func $core_func.output-stream.blocking-write-and-flush
        (canon lower (func $streams "[method]output-stream.blocking-write-and-flush") (memory $M))
    )
    (core instance $core_instance.streams
        (export "[method]output-stream.blocking-write-and-flush" (func $core_func.output-stream.blocking-write-and-flush))
    )

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

    ;; lift core func to component bridge func via core module/instance
    (core module $core_module
        ;; memory
        (import "root" "memory" (memory $memory 17))

        ;; dependencies
        (import "wasi:cli/stdout@0.2.0" "get-stdout"
            (func $get-stdout (result i32))
        )
        (import "wasi:io/streams@0.2.2" "[method]output-stream.blocking-write-and-flush"
            (func $output-stream.blocking-write-and-flush (param i32 i32 i32 i32))
        )

        ;; read-only data
        (data $message (i32.const 0) "Hello, world!\n")

        ;; entrypoint
        (func (export "main") (result i32)
            (local $stdout i32)
            (local.set $stdout (call $get-stdout))

            (call $output-stream.blocking-write-and-flush
                (local.get $stdout)
                (i32.const 0)
                (i32.const 14)
                (i32.const 16)
            )

            (i32.const 0)
        )
    )
    (core instance $core_instance (instantiate $core_module
        (with "root" (instance $root))
        (with "wasi:cli/stdout@0.2.0" (instance $core_instance.stdout))
        (with "wasi:io/streams@0.2.2" (instance $core_instance.streams))
    ))
    (func $bridge (result (result))
        (canon lift (core func $core_instance "main"))
    )
    
    ;; construct component with the lifted component func
    (component $main
        (import "bridge" (func $run-impl (result (result))))
        (export "run" (func $run-impl))
    )
    (instance $main (instantiate $main
        (with "bridge" (func $bridge))
    ))

    ;; export instance of expected interface e.g. wasi:cli/run
    (export "wasi:cli/run@0.2.0" (instance $main))
)
