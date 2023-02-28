(in-package :vs/video)

(vs::défclass Brain
              (
               ;; osc
               (port-out 30000)
               (port-in  30001)
               (sender)
               (recver)
               ;; geom
               (rect)
               )
              (vs/video::BrainBase)
              )

(defmethod initialize-instance :after ((brain Brain) &key)
  (!launch brain)
  (setf (:sender brain) (make-instance 'vs::Osc-sender :port (:port-out brain)))
  (setf (:recver brain) (make-instance 'vs::Osc-receiver :port (:port-in brain)))
  (vs::add-resp (:recver brain) "/scope" (lambda (&rest rsl) (eval `(!from-scope ,brain ,@rsl))))
  (sleep 1)
  (!kiss brain)
  )

(defmethod !kiss ((brain Brain) &key)
  (loop for l from 0 below (:lins brain) do
       (loop for c from 0 below (:cols brain) do
            (let* (
                   (id (+ c (* l (:cols brain))))
                   (player (make-instance 'Player :id id :brain brain :rep (:rep brain)))
                   )
              (setf (:players brain) (append (:players brain) (list player)))
              (!send player "new")
              ))))

(defmethod !launch ((brain Brain) &key)
  (unless (:scope-path brain)
    (setf (:scope-path brain)
          (vs::get-first-existing-path
           "/data/git/esonoclaste/e-sonoscope/build/Debug/e-sonoscope/e-sonoscope"
           "/data/git/esonoclaste/e-sonoscope/esonoscope/xcode/build/Debug/esonoscope.app/Contents/MacOS/esonoscope"
           )))
    
  (print (:scope-path brain))
  (when (:scope-path brain)
    (vs::launch-threaded-stdout (:scope-path brain) "scope" (:port-out brain) (:port-in brain))
    ))

(defun !from-scope (brain &rest args)
  (let* (
         (id (first args))
         (comm (second args))
         (val (third args))
         (player (nth id (:players brain)))
         )
    (when (string= comm "dur_sec") (setf (:dur-sec player) val))
    (when (string= comm "pos_sec")
      (setf (:pos-sec player) val)
      (when (= id 0) (!send player "display_text" (format nil "~,1f" val)))
      )
    ))


(defmethod !quit ((brain Brain) &key)
  (ignore-errors
    (!send brain "quit")
    (vs::!close (:sender brain))
    (vs::!close (:recver brain))
    ))

(defmethod !send ((brain Brain) &rest args)
  (eval `(vs::send (:sender ,brain) "/scope" -1 ,@args))
  )

(defmethod !geom ((brain Brain) &key (x 0) (y 0) (w 400) (h 300))
  ;;(setf (:rect brain) (make-instance 'Rectangle :x x :y y :w w :h h))
  (!send brain "geometry" (float x) (float y)  (float w)  (float h))
  )

;; -------------------------------------------------------------------
;; ---------------------------------- PLAYER -------------------------
;; -------------------------------------------------------------------
(vs::défclass Player
              (
               )
              (vs/video::PlayerBase)
              )

(defmethod !send ((player Player) &rest args)
  (eval `(vs::send (:sender (:brain ,player)) "/scope" (:id ,player) ,@args))
  )

(defmethod !geom ((player Player) &key (x 0) (y 0) (w 400) (h 300))
  ;;(!set-x (:rect player) x)
  (!send player "geometry" (float x) (float y)  (float w)  (float h))
  )


(defmethod !load ((player Player) path &key (start 0) (end nil) (dur nil) (vol01 nil))
  "start, end, dur : float in seconds"

  (when end (setf dur (- end start)))
  
  (setf (:path player) path)
  (if (:rep player)
      (if (uiop:file-exists-p (vs::+str (:rep player) path))
          (setf path (vs::+str (:rep player) path))
          (progn (format t "~% not found ~a" path) (return-from !load)))
      (unless (uiop:file-exists-p path) (format t "~% not found ~a" path)
              (return-from !load)))

  (if dur
      (!send player "load" path start dur)
      (!send player "load" path)
      )

  (when (and (string= path (:path player)) dur) (!send player "set_segment" start dur))
  (when vol01 (!vol01 player vol01))
  )

(defmethod !vol01 ((player Player) vol01) (!send player "vol01" vol01))
(defmethod !pause ((player Player)) (!send player "pause"))
(defmethod !play ((player Player)) (!send player "play"))
(defmethod !play-pause ((player Player)) (!send player "play_pause"))
(defmethod !seek ((player Player) pos-sec) (!send player "seek_sec" pos-sec))

(defmethod !close ((player Player) &key)
  (vs::!close (:sender player))
  (vs::!close (:recver player))
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; LIVECODING/ANNOTATION FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defmethod p ((player Player) &optional (start-sec nil) (dur-sec nil))
  (if dur-sec
      (!send player "set_segment" (float start-sec) (float dur-sec))
      (when start-sec (!seek player (float start-sec)))
      )
  (!play player)
  dur-sec
  )


(dbg "vs/video-scope loaded")
