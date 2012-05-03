#lang racket/gui
(require sgl/gl
         sgl/gl-vectors
         racket/mpair
         "drawtext.rkt")
(provide Inventory%)


;------------------------------------------------------------------------------
;Class: Inventory%
;Description: The class representing the player's inventory.
;------------------------------------------------------------------------------
(define Inventory%
  (class object%
    (super-new)
    (init-field width height things)
    (field (grid (make-vector height))
           (cursorx 0)
           (cursory 0))
    
    ;------------------------------------------------------------------------------
    ;gridloop: a short looping method to initialize the inventory grid with unique rows. We must 
    ; use this approach since initializing grid to (make-vector height (make-vector width #f)) creates 
    ; a grid with the _SAME_ object in all the rows, and mutating one will mutate all the others.
    ;params:
    ; rownum - the number of rows passed.
    ;------------------------------------------------------------------------------
    (define/private (gridloop rownum)
      (when (< rownum height)
        (vector-set! grid rownum (make-vector width #f))
        (gridloop (+ rownum 1))))
    
    (gridloop 0)
    
    ;------------------------------------------------------------------------------
    ;add-thing: adds an object to the inventory.
    ;params:
    ; thing - the thing to be added.
    ;------------------------------------------------------------------------------
    (define/public (add-thing! thing)
      (set! things (mappend things (mlist thing)))
      (update-inventory))
    
    ;------------------------------------------------------------------------------
    ;update-inventory: Updates the inventory grid with data from the inventory's list of things.
    ;------------------------------------------------------------------------------
    (define/private (update-inventory)
      (let ((number-of-things (mlength things))
            (thingcounter 0))
        (define (yloop rownum)
          (when (< rownum height)
            (define row (vector-ref grid rownum))
            (define (xloop colnum)
              (when (< colnum width)
                (if (< thingcounter number-of-things) 
                    (let ((thing (mlist-ref things thingcounter)))
                      (vector-set! row colnum thing)
                      (set! thingcounter (+ thingcounter 1)))
                    (begin 
                      (vector-set! row colnum #f)))
                (xloop (+ colnum 1))))
            (xloop 0)
            (vector-set! grid rownum row)
            (yloop (+ rownum 1))))
        (yloop 0)))
    
    
    ;------------------------------------------------------------------------------
    ;action: Reacts to player input and moves the current position in the grid.
    ;params:
    ; direction - the direction in which to move the cursor, or another command.v
    ;------------------------------------------------------------------------------
    (define/public (action direction)
      (case direction
        ((up) (unless (= cursory 0)
                (set! cursory (- cursory 1))))
        ((down) (unless (= cursory (- height 1))
                  (set! cursory (+ cursory 1))))
        ((left) (unless (= cursorx 0)
                  (set! cursorx (- cursorx 1))))
        ((right) (unless (= cursorx (- width 1))
                   (set! cursorx (+ cursorx 1))))))
    
    
    ;------------------------------------------------------------------------------
    ;delete-thing!: Deletes a thing from the inventory's list of things.
    ;params:
    ; thing - the thing to be deleted.
    ;------------------------------------------------------------------------------
    (define/public (delete-thing! thing)
      (define (delete-iter list)
        (cond ((null? list) (error "Inventory is empty"))
              ((eq? (mcar list) thing)
               (set! list (mcdr list))
               list)
              ((null? (mcdr list)) (error "Thing not found"))
              ((eq? (mcar (mcdr list)) thing)
               (set-mcdr! list (mcdr (mcdr list)))
               list)
              (else (mcons (mcar list) (delete-iter (mcdr list))))))
      (set! things (delete-iter things))
      (update-inventory))
    
    ;------------------------------------------------------------------------------
    ;draw: Draws the inventory on the screen.
    ;params:
    ; texture-list the global texture list passed on from the caller
    ;------------------------------------------------------------------------------
    (define/public (draw texture-list)
      (glDisable GL_TEXTURE_2D)
      (define (yloop row)
        (define (xloop col)
          (when (< col width)
            (let ((thing (vector-ref (vector-ref grid row) col)))
              
              (glPushMatrix)
              (glTranslatef (* col 100) (* row 50) 0)
              
              (glColor4f 0 0 0 0)
              (glBegin GL_TRIANGLE_STRIP)
              (glVertex2i 0 0)
              (glVertex2i 100 0)
              (glVertex2i 0 50)
              (glVertex2i 100 50)
              (glEnd)
              (if (and (= cursorx col) (= cursory row))
                  (glColor3f 0.7 0.7 0.65)
                  (glColor3f 0.5 0.5 0.45))
              (glBegin GL_TRIANGLE_STRIP)
              (glVertex2i 0 0)
              (glVertex2i 99 0)
              (glVertex2i 0 49)
              (glVertex2i 99 49)
              (glEnd)
              (if (not (eq? thing #f))
                  (begin
                    (glColor3f 1 0 0)
                    (glEnd)
                    (draw-text 10 10 0.7 (get-field inv-name thing) texture-list))
                  (void))
              (glPopMatrix))
            (xloop (+ col 1))))
        (when (< row height)
          (xloop 0)
          (yloop (+ row 1))))
      (yloop 0)
      (glEnable GL_TEXTURE_2D))))