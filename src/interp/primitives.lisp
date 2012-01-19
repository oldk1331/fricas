(in-package "BOOT")

;;; Fast array accessors

(defmacro QAREF1(v i)
`(aref (the (simple-array T (*)) ,v) ,i))

(defmacro QSETAREF1(v i s)
    `(setf (aref (the (simple-array T (*)) ,v) ,i) ,s))

;;; arrays of arbitrary offset

(defmacro QAREF1O(v i o)
    `(aref (the (simple-array T (*)) ,v) (|sub_SI| ,i ,o)))

(defmacro QSETAREF1O (v i s o)
    `(setf (aref (the (simple-array T (*)) ,v)
                 (|sub_SI| ,i ,o))
           ,s))

(defmacro QAREF2O(m i j oi oj)
    `(QAREF1O (QAREF1O ,m ,i ,oi) ,j ,oj))

(defmacro QSETAREF2O (m i j r oi oj)
    `(QSETAREF1O (QAREF1O ,m ,i ,oi) ,j ,r ,oj))


;;; array creation

(defun MAKEARR1 (size init)
    (make-array size :initial-element init))

;;; Vectors of 32-bit numbers

(defmacro ELT32(v i)
    `(aref (the (simple-array (unsigned-byte 32) (*)) ,v) ,i))

(defmacro SETELT32(v i s)
    `(setf (aref (the (simple-array (unsigned-byte 32) (*)) ,v) ,i)
           ,s))
#+:sbcl
(progn

(defmacro sbcl-make-u32-vector(n)
    (multiple-value-bind (typetag n-bits)
        (SB-IMPL::%VECTOR-WIDETAG-AND-N-BITS '(unsigned-byte 32))
        `(SB-KERNEL:ALLOCATE-VECTOR ,typetag ,n
                       (ceiling (* ,n ,n-bits) sb-vm:n-word-bits))))

(defun GETREFV32(n x)
    (let ((vec (sbcl-make-u32-vector n)))
        (fill vec x)
        vec))

)

#-:sbcl
(defun GETREFV32(n x) (make-array n :initial-element x
                                     :element-type '(unsigned-byte 32)))

(defmacro QV32LEN(v)
    `(length (the (simple-array (unsigned-byte 32) (*)) ,v)))

;;; Matrix operations

(defmacro MAKE-U32-MATRIX (n m)
   `(make-array (list ,n ,m) :element-type '(unsigned-byte 32)))

(defmacro MAKE-U32-MATRIX1 (n m s)
   `(make-array (list ,n ,m) :element-type '(unsigned-byte 32)
           :initial-element ,s))

(defmacro U32AREF2(v i j)
   `(aref (the (simple-array (unsigned-byte 32) (* *)) ,v) ,i ,j))

(defmacro U32SETAREF2(v i j s)
   `(setf (aref (the (simple-array (unsigned-byte 32) (* *)) ,v) ,i ,j)
          ,s))

(defmacro U32ANROWS(v)
    `(array-dimension (the (simple-array (unsigned-byte 32) (* *)) ,v) 0))

(defmacro U32ANCOLS(v)
    `(array-dimension (the (simple-array (unsigned-byte 32) (* *)) ,v) 1))

;;; Modular arithmetic

(deftype machine-int () '(unsigned-byte 64))

;;; (x*y + z) using 32-bit x and y and 64-bit z and assuming that
;;; intermediate results fits into 64 bits
(defmacro QSMULADD64-32 (x y z)
    `(the machine-int
         (+ (the machine-int
               (* (the (unsigned-byte 32) ,x)
                  (the (unsigned-byte 32) ,y)))
            (the machine-int ,z))))

(defmacro QSMUL64-32 (x y)
    `(the machine-int
         (* (the (unsigned-byte 32) ,x)
            (the (unsigned-byte 32) ,y))))


(defmacro QSMOD64-32 (x p)
    `(the (unsigned-byte 32)
         (rem (the machine-int ,x) (the (unsigned-byte 32) ,p))))

(defmacro QSMULADDMOD64-32 (x y z p)
    `(QSMOD64-32 (QSMULADD64-32 ,x ,y ,z) ,p))

(defmacro QSDOT2-64-32 (a1 b1 a2 b2)
    `(QSMULADD64-32 ,a1 ,b1 (QSMUL64-32 ,a2 ,b2)))

(defmacro QSDOT2MOD64-32 (a1 b1 a2 b2 p)
    `(QSMOD64-32 (QSDOT2-64-32 ,a1 ,b1 ,a2 ,b2) , p))

(defmacro QSMULMOD32 (x y p)
    `(QSMOD64-32 (QSMUL64-32 ,x ,y) ,p))

;;; Modular scalar product

(defmacro QMODDOT0 (eltfun varg1 varg2 ind1 ind2 kk s0 p)
    `(let ((s ,s0)
           (v1 ,varg1)
           (v2 ,varg2)
           (i1 ,ind1)
           (i2 ,ind2)
           (k0 ,kk)
           (k 0))
          (declare (type machine-int s)
                   (type fixnum i1 i2 k k0))
          (prog ()
             l1
              (if (>= k k0) (return (QSMOD64-32 s ,p)))
              (setf s (QSMULADD64-32 (,eltfun v1 (|add_SI| i1 k))
                                     (,eltfun v2 (|add_SI| i2 k))
                                     s))
              (setf k (|inc_SI| k))
              (go l1))))

(defmacro QMODDOT32 (v1 v2 ind1 ind2 kk s0 p)
     `(QMODDOT0 ELT32 ,v1 ,v2 ,ind1 ,ind2 ,kk ,s0 ,p))

;;; Floating point macros

;; Closure CL has buggy floating point optimizer, so for it we need
;; to omit type declarations to disable optimization
#-:openmcl
(defmacro DEF_DF_BINOP (name op)
   `(defmacro ,name (x y) `(the double-float (,',op (the double-float ,x)
                                                    (the double-float ,y)))))
#+:openmcl
(defmacro DEF_DF_BINOP (name op) `(defmacro ,name (x y) `(,',op ,x ,y)))

(DEF_DF_BINOP |add_DF| +)
(DEF_DF_BINOP |mul_DF| *)
(DEF_DF_BINOP |max_DF| MAX)
(DEF_DF_BINOP |min_DF| MIN)
(DEF_DF_BINOP |sub_DF| -)
(DEF_DF_BINOP |div_DF| /)

#-:openmcl
(progn
(defmacro |less_DF| (x y) `(< (the double-float ,x)
                                             (the double-float ,y)))
(defmacro |eql_DF| (x y) `(EQL (the double-float ,x)
                                             (the double-float ,y)))
(defmacro |expt_DF_I| (x y) `(EXPT (the double-float ,x)
                                 (the integer ,y)))
(defmacro |expt_DF| (x y) `(EXPT (the double-float ,x)
                                  (the double-float ,y)))
(defmacro |mul_DF_I| (x y) `(* (the double-float ,x)
                                  (the integer ,y)))
(defmacro |div_DF_I| (x y) `(/ (the double-float ,x)
                                  (the integer ,y)))
(defmacro |zero?_DF| (x) `(ZEROP (the double-float ,x)))
(defmacro |negative?_DF| (x) `(MINUSP (the double-float ,x)))
(defmacro |sqrt_DF| (x) `(SQRT (the double-float ,x)))
(defmacro |log_DF| (x) `(LOG (the double-float ,x)))

(defmacro DEF_DF_UNOP (name op)
    `(defmacro ,name (x) `(the double-float (,',op (the double-float ,x)))))
)

#+:openmcl
(progn
(defmacro |less_DF| (x y) `(<  ,x ,y))
(defmacro |eql_DF| (x y) `(EQL ,x ,y))
(defmacro |expt_DF_I| (x y) `(EXPT ,x ,y))
(defmacro |expt_DF| (x y) `(EXPT ,x ,y))
(defmacro |mul_DF_I| (x y) `(* ,x ,y))
(defmacro |div_DF_I| (x y) `(/ ,x ,y))
(defmacro |zero?_DF| (x) `(ZEROP ,x))
(defmacro |negative?_DF| (x) `(MINUSP ,x))
(defmacro |sqrt_DF|(x) `(SQRT ,x))
(defmacro |log_DF| (x) `(LOG ,x))

(defmacro DEF_DF_UNOP (name op)
    `(defmacro ,name (x) `(,',op ,x)))
)


(DEF_DF_UNOP |exp_DF| EXP)
(DEF_DF_UNOP |minus_DF| -)
(DEF_DF_UNOP |sin_DF| SIN)
(DEF_DF_UNOP |cos_DF| COS)
(DEF_DF_UNOP |tan_DF| TAN)
(DEF_DF_UNOP |atan_DF| ATAN)
(DEF_DF_UNOP |sinh_DF| SINH)
(DEF_DF_UNOP |cosh_DF| COSH)
(DEF_DF_UNOP |tanh_DF| TANH)
(DEF_DF_UNOP |qsqrt_DF| SQRT)
(DEF_DF_UNOP |qlog_DF| LOG)

;;; Machine integer operations

(defmacro DEF_SI_BINOP (name op)
   `(defmacro ,name (x y) `(the fixnum (,',op (the fixnum ,x)
                                                    (the fixnum ,y)))))
(DEF_SI_BINOP |add_SI| +)
(DEF_SI_BINOP |sub_SI| -)
(DEF_SI_BINOP |mul_SI| *)
(DEF_SI_BINOP |min_SI| min)
(DEF_SI_BINOP |max_SI| max)
(DEF_SI_BINOP |rem_SI| rem)
(DEF_SI_BINOP |quo_SI_aux| truncate)
(DEF_SI_BINOP |lshift_SI| ash)
(DEF_SI_BINOP |and_SI| logand)
(DEF_SI_BINOP |or_SI| logior)
(DEF_SI_BINOP |xor_SI| logxor)
(defmacro |quo_SI|(a b) `(values (|quo_SI_aux| ,a ,b)))

(defmacro DEF_SI_UNOP (name op)
    `(defmacro ,name (x) `(the fixnum (,',op (the fixnum ,x)))))

(DEF_SI_UNOP |minus_SI| -)
(DEF_SI_UNOP |abs_SI| abs)
(DEF_SI_UNOP |inc_SI| 1+)
(DEF_SI_UNOP |dec_SI| 1-)
(DEF_SI_UNOP |not_SI| lognot)

(defmacro DEF_SI_ARG_BINOP (name op)
   `(defmacro ,name (x y) `(,',op (the fixnum ,x) (the fixnum ,y))))

(DEF_SI_ARG_BINOP |eql_SI| eql)
(DEF_SI_ARG_BINOP |less_SI| <)
(DEF_SI_ARG_BINOP |greater_SI| >)

(defmacro DEF_SI_ARG_UNOP (name op)
   `(defmacro ,name (x) `(,',op (the fixnum ,x))))

(DEF_SI_ARG_UNOP |zero?_SI| zerop)
(DEF_SI_ARG_UNOP |negative?_SI| minusp)
(DEF_SI_ARG_UNOP |odd?_SI| oddp)

; Small finite field operations
;
;; following macros assume 0 <= x,y < z
;; qsaddmod additionally assumes that rsum has correct value even
;; when (x + y) exceeds range of a fixnum.  This is true if
;; fixnums use modular arithmetic with no overflow checking,
;; but according to ANSI Lisp the result is undefined in
;; such case.

(defmacro |addmod_SI| (x y z)
   `(let* ((sum (|add_SI| ,x ,y))
           (rsum (|sub_SI| sum ,z)))
         (if (|negative?_SI| rsum) sum rsum)))

(defmacro |submod_SI| (x y z)
    `(let ((dif (|sub_SI| ,x ,y)))
         (if (|negative?_SI| dif) (|add_SI| dif ,z) dif)))

(defmacro |mulmod_SI| (x y z) `(rem (* (the fixnum ,x) (the fixnum ,y))
                                     ,z))

;;; Double precision arrays and matrices

(defmacro MAKE-DOUBLE-VECTOR (n)
   `(make-array (list ,n) :element-type 'double-float))

(defmacro MAKE-DOUBLE-VECTOR1 (n s)
   `(make-array (list ,n) :element-type 'double-float :initial-element ,s))

(defmacro DELT(v i)
   `(aref (the (simple-array double-float (*)) ,v) ,i))

(defmacro DSETELT(v i s)
   `(setf (aref (the (simple-array double-float (*)) ,v) ,i)
           ,s))

(defmacro DLEN(v)
    `(length (the (simple-array double-float (*)) ,v)))

(defmacro MAKE-DOUBLE-MATRIX (n m)
   `(make-array (list ,n ,m) :element-type 'double-float))

(defmacro MAKE-DOUBLE-MATRIX1 (n m s)
   `(make-array (list ,n ,m) :element-type 'double-float
           :initial-element ,s))

(defmacro DAREF2(v i j)
   `(aref (the (simple-array double-float (* *)) ,v) ,i ,j))

(defmacro DSETAREF2(v i j s)
   `(setf (aref (the (simple-array double-float (* *)) ,v) ,i ,j)
          ,s))

(defmacro DANROWS(v)
    `(array-dimension (the (simple-array double-float (* *)) ,v) 0))

(defmacro DANCOLS(v)
    `(array-dimension (the (simple-array double-float (* *)) ,v) 1))

;;; We implement complex array as arrays of doubles -- each
;;; complex number occupies two positions in the real
;;; array.

(defmacro MAKE-CDOUBLE-VECTOR (n)
   `(make-array (list (* 2 ,n)) :element-type 'double-float))

(defmacro CDELT(ov oi)
   (let ((v (gensym))
         (i (gensym)))
   `(let ((,v ,ov)
          (,i ,oi))
      (cons
          (aref (the (simple-array double-float (*)) ,v) (* 2 ,i))
          (aref (the (simple-array double-float (*)) ,v) (+ (* 2 ,i) 1))))))

(defmacro CDSETELT(ov oi os)
   (let ((v (gensym))
         (i (gensym))
         (s (gensym)))
   `(let ((,v ,ov)
          (,i ,oi)
          (,s ,os))
        (setf (aref (the (simple-array double-float (*)) ,v) (* 2 ,i))
           (car ,s))
        (setf (aref (the (simple-array double-float (*)) ,v) (+ (* 2 ,i) 1))
           (cdr ,s))
        ,s)))

(defmacro CDLEN(v)
    `(truncate (length (the (simple-array double-float (*)) ,v)) 2))

(defmacro MAKE-CDOUBLE-MATRIX (n m)
   `(make-array (list ,n (* 2 ,m)) :element-type 'double-float))

(defmacro CDAREF2(ov oi oj)
   (let ((v (gensym))
         (i (gensym))
         (j (gensym)))
   `(let ((,v ,ov)
          (,i ,oi)
          (,j ,oj))
        (cons
            (aref (the (simple-array double-float (* *)) ,v) ,i (* 2 ,j))
            (aref (the (simple-array double-float (* *)) ,v)
                  ,i (+ (* 2 ,j) 1))))))

(defmacro CDSETAREF2(ov oi oj os)
   (let ((v (gensym))
         (i (gensym))
         (j (gensym))
         (s (gensym)))
   `(let ((,v ,ov)
          (,i ,oi)
          (,j ,oj)
          (,s ,os))
         (setf (aref (the (simple-array double-float (* *)) ,v) ,i (* 2 ,j))
               (car ,s))
         (setf (aref (the (simple-array double-float (* *)) ,v)
                     ,i (+ (* 2 ,j) 1))
               (cdr ,s))
         ,s)))

(defmacro CDANROWS(v)
    `(array-dimension (the (simple-array double-float (* *)) ,v) 0))

(defmacro CDANCOLS(v)
    `(truncate
         (array-dimension (the (simple-array double-float (* *)) ,v) 1) 2))


(defstruct (SPAD-KERNEL 
          (:print-function
               (lambda (p s k)
                   (format s "#S~S" (list 
                        'SPAD-KERNEL
                         :OP (SPAD-KERNEL-OP p) 
                         :ARG (SPAD-KERNEL-ARG p)
                         :NEST (SPAD-KERNEL-NEST p))))))
           OP ARG NEST (POSIT 0))

(defmacro SET-SPAD-KERNEL-POSIT(s p) `(setf (SPAD-KERNEL-POSIT ,s) ,p))

(defun |makeSpadKernel|(o a n) (MAKE-SPAD-KERNEL :OP o :ARG a :NEST n))

; Hashtable accessors

(defmacro HGET (table key)
   `(gethash ,key ,table))

(defmacro HGET2 (table key default)
   `(gethash ,key ,table ,default))

(defmacro HPUT(table key value) `(setf (gethash ,key ,table) ,value))

(defmacro HREM (table key) `(remhash ,key ,table))

; Misc operations

(defmacro setelt (vec ind val) `(setf (elt ,vec ,ind) ,val))

(defmacro pairp (x) `(consp ,x))

(defmacro qcar (x) `(car (the cons ,x)))

(defmacro qcdr (x) `(cdr (the cons ,x)))

(defmacro qcaar (x)
 `(car (the cons (car (the cons ,x)))))

(defmacro qcadr (x)
 `(car (the cons (cdr (the cons ,x)))))

(defmacro qcdar (x)
 `(cdr (the cons (car (the cons ,x)))))

(defmacro qcddr (x)
 `(cdr (the cons (cdr (the cons ,x)))))

(defmacro qcsize (x)
 `(the fixnum (length (the simple-string ,x))))

(defmacro qrefelt (vec ind) `(svref ,vec ,ind))

(defmacro qrplaca (a b) `(rplaca (the cons ,a) ,b))

(defmacro qrplacd (a b) `(rplacd (the cons ,a) ,b))

(defmacro qsetrefv (vec ind val)
 `(setf (svref ,vec (the fixnum ,ind)) ,val))

(defmacro qsetvelt (vec ind val)
 `(setf (svref ,vec (the fixnum ,ind)) ,val))

(defmacro qvelt (vec ind) `(svref ,vec (the fixnum ,ind)))

(defmacro qvmaxindex (x)
 `(the fixnum (1- (the fixnum (length (the simple-vector ,x))))))

(defmacro qvsize (x)
 `(the fixnum (length (the simple-vector ,x))))

(defmacro qlessp(x y) `(< ,x ,y))

; macros needed for Spad:

(defmacro EXIT (&rest value) `(return-from SEQ ,@value))

(defmacro SEQ (&rest form)
  (let* ((body (reverse form))
         (val `(return-from seq ,(pop body))))
    (nsubstitute '(progn) nil body) ;don't treat NIL as a label
    `(block seq (tagbody ,@(nreverse body) ,val))))

(defmacro LETT (var val &rest L)
  (COND
    (|$QuickLet| `(SETQ ,var ,val))
    (|$compilingMap|
   ;; map tracing
     `(PROGN
        (SETQ ,var ,val)
        (COND (|$letAssoc|
               (|mapLetPrint| ,(MKQ var)
                              ,var
                              (QUOTE ,(KAR L))))
              ('T ,var))))
     ;; used for LETs in SPAD code --- see devious trick in COMP-TRAN-1
     ((ATOM var)
      `(PROGN
         (SETQ ,var ,val)
         (IF |$letAssoc|
             ,(cond ((null (cdr l))
                     `(|letPrint| ,(MKQ var) ,var (QUOTE ,(KAR L))))
                    ((and (eqcar (car l) 'SPADCALL) (= (length (car l)) 3))
                     `(|letPrint3| ,(MKQ var) ,var ,(third (car l)) (QUOTE ,(KADR L))))
                    (t `(|letPrint2| ,(MKQ var) ,(car l) (QUOTE ,(KADR L))))))
         ,var))
     ('T (ERROR "Cannot compileLET construct"))))

(defmacro SPADLET (A B)
  (if (ATOM A) `(SETQ ,A ,B)
      (BREAK)))

(defmacro SPADCALL (&rest L)
  (let ((args (butlast l))
	(fn (car (last l)))
	(gi (gensym)))
     ;; (values t) indicates a single return value
    `(let ((,gi ,fn))
       (the (values t)
	 (funcall
          (the #-(or :genera :lispworks)
                   (function ,(make-list (length l) :initial-element t) t)
               #+(or :genera :lispworks)function
	    (car ,gi))
	  ,@args
	  (cdr ,gi))))))

(defmacro SPADMAP(&rest args) `'(SPADMAP ,@args))

(defmacro |spadConstant| (dollar n)
 `(SPADCALL (svref ,dollar (the fixnum ,n))))

(defmacro |Record| (&rest args)
    (list '|Record0|
          (cons 'LIST
                (mapcar #'(lambda (x) (list 'CONS (MKQ (CADR x)) (CADDR x)))
                        args))))

(defmacro |Enumeration| (&rest args)
      (cons '|Enumeration0|
                    (mapcar #'(lambda (x) (list 'QUOTE x)) args)))

;;; Used for Record arguments
(defmacro |:| (tag expr) `(LIST '|:| ,(MKQ tag) ,expr))

(defmacro |Zero|() 0)
(defmacro |One|() 1)

;;; Needed by interpreter
(defmacro REPEAT (&rest L) (|expandREPEAT| L))
(defmacro COLLECT (&rest L) (|expandCOLLECT| L))

