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
;;     (type $t_streams (instance
;;         (export "output-stream" (type (sub resource)))
;;     ))
;;     (import "wasi:io/streams@0.2.2" (instance $streams (type $t_streams)))
;;     (alias export $streams "output-stream" (type $output-stream))
;; ;; 
;; ;;     (type $t_stdout (instance
;; ;;         (export "get-stdout" (func ((; as a ;)result (own $output-stream))))
;; ;;     ))
;; ;;     (import "wasi:cli/stdout@0.2.0" (instance $stdout (type $t_stdout)))
;; 
;;     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;;     (func $write_bytes (param "bytes" list<u8>) (result result)
;;         
;;     )

    (import "wasi:io/streams@0.2.2" (instance $streams
        (export "output-stream" (type (sub resource)))
    ))
    (alias export $streams "output-stream" (type $output-stream))

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    (core module $core_module
        (func (export "main") ((; as a ;)result i32)
            (i32.const 0)
        )
    )
    (core instance $core_instance (instantiate $core_module))

    (func $main-lifted ((; as a ;)result (result)) (
        canon lift (core func $core_instance "main")
    ))
    
    (component $my_component
        (import "f" (func $hoge ((; as a ;)result (result))))
        (export "run" (func $hoge))
    )
    (instance $my_instance (instantiate $my_component
        (with "f" (func $main-lifted))
    ))

    (export "wasi:cli/run@0.2.0" (instance $my_instance))
)
