;; does not work with sbcl !!
(cffi:load-foreign-library "libmpv.so")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;   GENERIC FUNCTIONS AND CLASS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#|
player --show-profile=libmpv
|#

;; create a function for getting properties
(cffi:defcfun ("mpv_get_property_string" ?prop) :string (ptr :pointer) (str :string))

(vs::défclass Player ((ptr)) (vs/video::PlayerBase))

(defmethod !set ((player Player) com arg1 &optional (arg2 "none"))
  (if arg2
      (eval `(cffi:foreign-funcall ,com :pointer (:ptr ,player) :string ,arg1 :string ,arg2))
      (eval `(cffi:foreign-funcall ,com :pointer (:ptr ,player) :string ,arg1))
      ))

(defmethod !set-option ((player Player) arg1 arg2)
  (!set player "mpv_set_option_string" arg1 arg2)
  )

(defmethod !set-comm ((player Player) arg)
  (!set player "mpv_command_string" arg)
  )

(defmethod !set-prop ((player Player) arg1 &optional (arg2 nil))
  (when (numberp arg1) (setf arg1 (write-to-string arg1)))
  (if arg2
      (progn
        (when (numberp arg2) (setf arg2 (write-to-string arg2)))
        (!set player "mpv_set_property_string" arg1 arg2)
        )
      (!set player "mpv_set_property_string" arg1)
      ))

(defmethod !get-prop ((player Player) prop)
  (?prop (:ptr player) prop)
  )

(defmethod initialize-instance :after ((player Player) &key)	
  (setf (:ptr player) (cffi:foreign-funcall "mpv_create" :pointer))

  (when t
    (!set-option player "osd-level" "0")
    (!set-option player "ao" "jack")
    (!set-option player "hwdec" "vaapi")
    (!set-option player "vo" "gpu")
    (!set-option player "border" "no")
    (!set-option player "ontop" "yes")
    (!set-option player "force-window" "yes")
    (!set-option player "on-all-workspaces" "yes")
    ;;(!set-option player "ontop-level" "system") ;; osx only
    ;; (!set-option player "geometry" "400x300+1800+0")
    (!set-option player "geometry" (format nil "~ax~a+~a+~a" (:w player) (:h player) (:x player) (:y player)))
    ;;(!set-option player "sub-codepage" "utf8")
    )
  
  (cffi:foreign-funcall "mpv_initialize" :pointer (:ptr player)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;; REMOTE FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defmethod !load ((player Player) path &key (start nil) (end nil) (dur nil) (volume nil))
  "start, end, dur : float in seconds"
  (unless (string= (:path player) path)
    (if (:rep player)
        (unless (uiop:file-exists-p (vs::+str (:rep player) path)) (format t "~% not found ~a" path) (return-from !load))
        (unless (uiop:file-exists-p path) (format t "~% not found ~a" path) (return-from !load))
        )
    (setf (:path player) path)
    (!reload player :start start :end end :dur dur :volume volume)
    ))

(defmethod !show-text ((player Player) text &optional (dt-msec 1000))
  (setf text (vs::replace-all text " " " "))
  (!set-comm player (vs::+str "show-text " text " " dt-msec))
  )

(defmethod !full ((player Player))
  (!set-option m "ontop" "no")
  (!set-prop player "fullscreen" "yes")
  )

(defmethod !unfull ((player Player))
  (!set-option m "ontop" "yes")
  (!set-prop player "fullscreen" "no")
  )

(defmethod !reload ((player Player) &key (start nil) (end nil) (dur nil) (volume nil))
  "start, end, dur : in seconds must be integers for libmpv to work!!"
  (when start (!set-prop player "start" (floor start)))
  (!set-prop player "end" nil)
  (!set-prop player "length" nil)

  (when *player-mode-play-with-duration*
    (vs::dbg *player-mode-play-with-duration*)
    (when dur (!set-prop player "length" (ceiling dur)))
    (when end (!set-prop player "end" (ceiling end)))
    )
  
  ;;(!vol player volume)
  (if (:rep player)
      (!set-comm player (vs::+str "loadfile " (:rep player) (:path player)))
      (!set-comm player (vs::+str "loadfile " (:path player)))
      ))

(defmethod ?pos-sec ((player Player))
  (format nil "~,1f" (vs::str2float (!get-prop player "time-pos")))
  )

(defmethod ?dur-sec ((player Player))
  (!get-prop player "duration")
  )

(defmethod !sec ((player Player) pos-sec)
  (!set-prop player "time-pos" (write-to-string pos-sec))
  )

(defmethod !+-sec ((player Player) +-sec)
  (!set-comm player (vs::+str "seek " +-sec " relative"))
  )

(defmethod !seek ((player Player) +-sec)
  (!set-comm player (vs::+str "seek " +-sec " relative"))
  )

(defmethod !play ((player Player) &key)
  (!set-comm player "set pause no")
  )

(defmethod !pause ((player Player))
  (!set-comm player "set pause yes")
  )

(defmethod !play-pause ((player Player))
  (!set-comm player "cycle pause")
  )

(defmethod !stop ((player Player)) (!set-comm player "stop"))

(defmethod !vol ((player Player) volume)
  (!set-prop player "volume" volume)
  )

(defmethod !speed ((player Player) speed)
  (!set-prop player "speed" speed)
  )

(defmacro !destroy (player)
  `(progn
     (when (boundp ',player)
       (cffi:foreign-funcall "mpv_terminate_destroy" :pointer (:ptr ,player))
       )))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; LIVECODING/ANNOTATION FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defmethod p ((player Player) &optional (start-sec nil) (dur-sec nil))
  (!reload player :start start-sec :dur dur-sec)
  dur-sec
  )

(dbg "vs/video-mpv loaded")
