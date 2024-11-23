
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
feat: Enhance core escrow functionality with timeouts

;; Additional constants
(define-constant ESCROW-FEE u100) ;; 1% fee
(define-constant DISPUTE-TIMEOUT u1440) ;; 24 hours in blocks

;; Define data vars
(define-data-var next-escrow-id uint u0)

;; Define escrow map
(define-map escrows
  uint
  {
    seller: principal,
    buyer: principal,
    amount: uint,
    status: (string-ascii 20),
    creation-time: uint,
    expiration-time: uint
  }
)

;; Create escrow with timeout
(define-public (create-escrow (buyer principal) (amount uint) (timeout uint))
  (let
    (
      (escrow-id (var-get next-escrow-id))
      (creation-block block-height)
      (expiration-block (+ block-height timeout))
    )
    (asserts! (> amount u0) ERR-INSUFFICIENT-AMOUNT)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    (map-set escrows escrow-id
      {
        seller: tx-sender,
        buyer: buyer,
        amount: amount,
        status: "pending",
        creation-time: creation-block,
        expiration-time: expiration-block
      }
    )
    (var-set next-escrow-id (+ escrow-id u1))
    (ok escrow-id)
  )
)

;; Release escrow with timeout check
(define-public (release-escrow (escrow-id uint))
  (let
    (
      (escrow (unwrap! (map-get? escrows escrow-id) ERR-NOT-FOUND))
      (fee (/ (* (get amount escrow) ESCROW-FEE) u10000))
    )
    (asserts! (is-eq (get status escrow) "pending") ERR-INVALID-STATUS)
    (asserts! (is-eq tx-sender (get buyer escrow)) ERR-NOT-AUTHORIZED)
    (asserts! (< block-height (get expiration-time escrow)) ERR-EXPIRED)
    
    (try! (as-contract (stx-transfer? (- (get amount escrow) fee) (get seller escrow))))
    (try! (as-contract (stx-transfer? fee CONTRACT-OWNER)))
    
    (map-set escrows escrow-id
      (merge escrow { status: "completed" })
    )
    (ok true)
  )
)
feat: Implement dispute resolution system

;; Update escrow map with dispute fields
(define-map escrows
  uint
  {
    seller: principal,
    buyer: principal,
    amount: uint,
    status: (string-ascii 20),
    creation-time: uint,
    expiration-time: uint,
    dispute-reason: (optional (string-utf8 500))
  }
)

;; Initiate dispute
(define-public (dispute-escrow (escrow-id uint) (reason (string-utf8 500)))
  (let
    (
      (escrow (unwrap! (map-get? escrows escrow-id) ERR-NOT-FOUND))
    )
    (asserts! (is-eq (get status escrow) "pending") ERR-INVALID-STATUS)
    (asserts! (or (is-eq tx-sender (get buyer escrow)) (is-eq tx-sender (get seller escrow))) ERR-NOT-AUTHORIZED)
    
    (map-set escrows escrow-id
      (merge escrow { 
        status: "disputed",
        dispute-reason: (some reason)
      })
    )
    (ok true)
  )
)

;; Resolve dispute
(define-public (resolve-dispute (escrow-id uint) (refund-percentage uint))
  (let
    (
      (escrow (unwrap! (map-get? escrows escrow-id) ERR-NOT-FOUND))
      (fee (/ (* (get amount escrow) ESCROW-FEE) u10000))
      (refund-amount (/ (* (get amount escrow) refund-percentage) u100))
      (seller-amount (- (- (get amount escrow) refund-amount) fee))
    )
    (asserts! (is-eq tx-sender (var-get admin-address)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status escrow) "disputed") ERR-INVALID-STATUS)
    (asserts! (<= refund-percentage u100) (err u400))
    
    (try! (as-contract (stx-transfer? refund-amount (get buyer escrow))))
    (try! (as-contract (stx-transfer? seller-amount (get seller escrow))))
    (try! (as-contract (stx-transfer? fee CONTRACT-OWNER)))
    
    (map-set escrows escrow-id
      (merge escrow { status: "resolved" })
    )
    (ok true)
  )
)

