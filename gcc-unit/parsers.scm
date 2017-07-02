(define-module (gcc-unit parsers)
  #:use-module (system base lalr)
  #:use-module (gcc-unit records)
  #:use-module (gcc-unit lexers)
  #:use-module (ice-9 match)
  #:use-module (ice-9 hash-table)
  #:use-module (srfi srfi-26) ; cut
  #:export (parse))

(define (reference value)
  `(reference ,value))

(define (make-parser)
  (lalr-parser
   (def @ value :) ; terminals
   (program (definition program) : (cons $1 $2)
            (*eoi*) : '())
   (definition (def @ id type-name attributes) : (list $3 $4 $5)
               (def @ id type-name) : (list $3 $4 '()))
   (attributes (attribute attributes) : (cons $1 $2)
               (attribute) : (cons $1 '()))
   (type-name (value) : (string->symbol $1)) ; At the meta level.
   (name (value) : (string->symbol $1))
   (id (value) : (string->symbol $1))
   (nonref-values ;(value nonref-values) : (string-append $1 " " $2)
                  (value) : $1)
   (values ;(value nonref-values) : (string-append $1 " " $2) ; special-case "strg: foo bar baz lngt: 11" - which is really a stupid way to write it but hey.
           (@ id) : (reference $2)
           (value) : $1)
   (attribute (name : values) : (cons $1 $3))))

; TODO eval the result, resolving "reference"s.

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

(define (create-record-instance id type-name attributes)
  (cons id
    (cond
      ((eq? type-name 'type_decl) (create-record-instance-by-lists type-decl '(name type scpe srcp chain) attributes '(name type chain)))
      (else (cons type-name attributes)))))

(define* (parse port #:optional (definition-creator create-record-instance))
  (let* ((entries ((make-parser) (make-lexer port) error))
         (entries (map (cut apply definition-creator <>) entries))
         (result (alist->hash-table entries)))
    ;(write (hash-ref result (string->symbol "1")))
    (hash-map->list cons result)))
