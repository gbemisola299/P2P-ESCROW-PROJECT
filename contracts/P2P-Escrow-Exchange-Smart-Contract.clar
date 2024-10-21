;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-INVALID-STATUS (err u400))

;; Define constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ESCROW-FEE u100) ;; 1% fee
(define-constant CONTRACT-NAME 'P2P-ESCROW-PROJECT)

;; Define data vars
(define-data-var next-escrow-id uint u0)

;; Define data maps
(define-map escrows
  uint
  {
    seller: principal,
    buyer: principal,
    amount: uint,
    status: (string-ascii 20)
  }
)
