;; ref: wasi:cli/run ↓
;; 
;; @since(version = 0.2.0)
;; interface run {
;;   /// Run the program.
;;   @since(version = 0.2.0)
;;   run: func() -> result;
;; }

(component
    (core module $my_core_mod
        (func (export "mod-main") (result i32)
            (i32.const 0))
    )

    (core instance $my_core_inst (instantiate $my_core_mod))
    (func $main_lifted (result (result)) (
        canon lift (core func $my_core_inst "mod-main")))
    
    (component $my_component
        (import "main" (func $g (result (result))))
        (export "run" (func $g))
    )

    (instance $my_instance (instantiate $my_component
        (with "main" (func $main_lifted))))

    (export "wasi:cli/run@0.2.0" (instance $my_instance))
)