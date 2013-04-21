;; compile ffigen4 (a version of gcc that parses headers and outputs
;; lisp files)
;; write this file:
;; martin@acergpu:~/src/ccl/x86-headers64/dip/C$ cat populate.sh
;; #!/bin/sh
;; h-to-ffi.sh /usr/local/include/diplib.h
;; h-to-ffi.sh /usr/local/include/dipio.h
#+nil
(progn
  ;; calls populate.sh and creates cdb files, I had to make sure
  ;; the cdb files contain some data

  ;; martin@acergpu:~$ ls -l src/ccl/x86-headers64/dip
  ;; total 500
  ;; drwxr-xr-x 3 martin martin   4096 Apr 20 23:08 C
  ;; -rw-r--r-- 1 martin martin  50021 Apr 20 23:42 constants.cdb
  ;; -rw-r--r-- 1 martin martin 115717 Apr 20 23:42 functions.cdb
  (require "PARSE-FFI")
  (ccl::parse-standard-ffi-files :dip))

(in-package :ccl)

(eval-when (:compile-toplevel :execute)
  (use-interface-dir :dip))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (open-shared-library "/usr/local/lib/libdip.so")
  (open-shared-library "/usr/local/lib/libdipio.so"))


(defmacro check (fn)
  `(let ((r ,fn))
     (unless  (%null-ptr-p r) #+nil(= #$DIP_OK (%ptr-to-int r))
       (error "error with ~a: ~a." ',fn (list (pref r :dip_<E>rror.function)
					      (pref r :dip_<E>rror.message))))))


(defun dip-init ()
 (check (#_dip_Initialise))
 (check (#_dipio_Initialise)))

(defun dip-exit ()
  (check (#_dip_Exit))
  (check (#_dipio_Exit)))

;; this runs automatically when the current file is loaded
#+nil(def-load-pointers initialize-dip ()
  (dip-init))

#+nil
(progn
  (check (#_dip_Initialise))
  (check (#_dipio_Initialise)))

#+nil
(rlet ((res :dip_<R>esources)
       (img :dip_<I>mage)
       (img2 :dip_<I>mage))
  (#_dip_ResourcesNew res 0)
  (#_dip_ImageNew img res)
  (#_dip_ImageNew img2 res))


(defmacro with-resources (res &body body)
  (let ((pres (gensym)))
   `(rlet ((,pres :dip_<R>esources))
      (check (#_dip_ResourcesNew ,pres 0))
      (prog1 
	  (let ((,res (pref ,pres :dip_<R>esources)))
	    ,@body)
	(check (#_dip_ResourcesFree ,pres))))))

(defun string-new (str r)
  (with-cstr (str-c str)
   (rlet ((str-dip :dip_<S>tring))
     (check (#_dip_StringNew str-dip 0 str-c r))
     (pref str-dip :dip_<S>tring))))

(defun image-new (r)
  (rlet ((img :dip_<I>mage))
    (check (#_dip_ImageNew img r))
    (pref img :dip_<I>mage)))

(defun read-image (fn r &key image)
  (let ((img (if image
		 image
		 (image-new r))))
    (rlet ((recognized-p :dip_<B>oolean))
      (check (#_dipio_ImageRead img
				(string-new fn r)
				0	  ;; format 
				#$DIP_FALSE ;; add extension
				recognized-p))
      (unless (= 1 (pref recognized-p :dip_<B>oolean))
	(error "dipio_ImageRead didn't recognize ~a." fn)))
    img))

#+nil
(with-resources r
  (read-image "/home/martin/dip/images/cross.ics" r))

(defun physical-dimensions-new (r &key (dimensionality 2)
				    (dims 1d0)
				    (orig 0d0)
				    (unit "mm")
				    (intensity 1000d0)
				    (offset 100d0)
				    (intensity-unit "photo-electrons"))
  (rlet ((dims-dip :dip_<P>hysical<D>imensions))
    (check (#_dip_PhysicalDimensionsNew dims-dip dimensionality
					dims orig (string-new unit r)
					intensity offset (string-new intensity-unit r)
					r))
    (pref dims-dip :dip_<P>hysical<D>imensions)))

(defun compression-new (&key (method #$DIPIO_CMP_NONE)
			  (level 0))
  (rlet ((comp-dip :dipio_<C>ompression))
    (setf (pref comp-dip :dipio_<C>ompression.method) method
	  (pref comp-dip :dipio_<C>ompression.level) level)
    (pref comp-dip :dipio_<C>ompression)))

(defun write-image (img fn r &key (format 0) compression)
  (check (#_dipio_ImageWrite img (string-new fn r)
			     (physical-dimensions-new r)
			     format
			     (if compression
				 compression
				 (compression-new)))))

#+nil
(with-resources r
  (let ((img (read-image "/home/martin/dip/images/cross.ics" r)))
    (write-image img "/dev/shm/o.ics" r)))

