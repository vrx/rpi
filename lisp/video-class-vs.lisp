(defpackage #:vs/video
  (:use #:cl
        #:vs
        )
  (:export
   #:!geom
   #:p
   #:!load
   #:!quit
   #:!stop
   #:!play
   #:!pause
   #:!speed
   #:!set-rep
   #:!destroy
   #:!show-text
   )
  )

(in-package :vs/video)

(defparameter *player-mode-play-with-duration* nil) ;

(vs::défclass BrainBase
              (
               (cols 2) ; columns
               (lins 3) ; lines
               (rep) ;; media rep
               (scope-path) ;; e-sonoscope path
               (players (list))
               ))

(vs::défclass Brain () (BrainBase))

(vs::défclass PlayerBase
              (
               (id 0)
               (rep) ;; media rep
               (path) ;; media path
               (dur-sec)
               (pos-sec)
               (w 400) (h 300) (x 0) (y 0)
               (geom (make-instance 'vs::Rectangle :x 0 :y 0 :w 400 :h 300))
               ;; and a brain
               (brain)
               )
              )

(defmethod !vol01 ((player PlayerBase) vol01))
  
(defmethod !fi ((player PlayerBase) &optional (dt 0.1))
  (let ((vol 1)
        (steps 10)
        )
    (loop for gain from 0 to 1 by (/ 1 steps) do
         (!vol01 player (* gain vol))
         (sleep (/ dt steps))
         )))

(defmethod !fo ((player PlayerBase) &optional (dt 0.1))
  (let ((vol 1)
        (steps 10)
        )
    (loop for gain from 1 downto 0 by (/ 1 steps) do
         (!vol01 player (* gain vol))
         (sleep (/ dt steps))
         )))

(defun !set-rep (player rep)
  (setf (:rep player) rep)
  )

#|
(vs::défclass Player ())
(defun !launch (player))
(defun !geom (player &key (id -1) (x 0) (y 0) (w 400) (h 300)))
(defun !play (player))
(defun !pause (player))
(defun !playpause (player))
|#
