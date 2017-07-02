(define-module (gcc-unit serializers)
  #:use-module (gcc-unit records)
  #:use-module (ice-9 hash-table)
  #:use-module (srfi srfi-26)) ; cut

(define sentinel (gensym))
(define (hash-ref-or-die hash-table key err)
    (let ((result (hash-ref hash-table key sentinel)))
      (if (eq? result sentinel)
        (err key)
        result)))

(define* (create-record-instance-by-lists proc attribute-names attribute-definitions #:optional (required-attribute-names attribute-names))
  (let* ((attribute-definitions (alist->hash-table attribute-definitions)))
      (write "X")
    (write (hash-map->list cons attribute-definitions))
  (let ((constructor-args (map (cut hash-ref-or-die attribute-definitions <> (lambda (key) (if (member key required-attribute-names) (error key) #f))) attribute-names)))
    (apply proc constructor-args))))

(define-public (deserialize-record-instance type-name attributes)
  (cond
    ((eq? type-name 'type_decl) (create-record-instance-by-lists type-decl '(name type scpe srcp chain) attributes '(name type chain)))
    (else (cons type-name attributes))))
