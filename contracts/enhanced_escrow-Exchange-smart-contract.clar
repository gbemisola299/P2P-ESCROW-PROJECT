
;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-INVALID-STATUS (err u400))
(define-constant ERR-EXPIRED (err u408))
(define-constant ERR-ALREADY-DISPUTED (err u409))
(define-constant ERR-INSUFFICIENT-AMOUNT (err u402))

;; Define constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant CONTRACT-NAME 'P2P-ESCROW-V2)

;; Define data vars
(define-data-var admin-address principal CONTRACT-OWNER)

;; Admin functions
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin-address)) ERR-NOT-AUTHORIZED)
    (var-set admin-address new-admin)
    (ok true)
  )
)

;; Basic read-only function
(define-read-only (get-admin)
  (var-get admin-address)
)