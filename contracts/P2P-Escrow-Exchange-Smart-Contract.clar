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

;; Create a new escrow
(define-public (create-escrow (buyer principal) (amount uint))
  (let
    (
      (escrow-id (var-get next-escrow-id))
    )
    (asserts! (> amount u0) (err u400))
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set escrows escrow-id
      {
        seller: tx-sender,
        buyer: buyer,
        amount: amount,
        status: "pending"
      }
    )
    (var-set next-escrow-id (+ escrow-id u1))
    (ok escrow-id)
  )
)

;; Release funds to the seller
(define-public (release-escrow (escrow-id uint))
  (let
    (
      (escrow (unwrap! (map-get? escrows escrow-id) ERR-NOT-FOUND))
      (fee (/ (* (get amount escrow) ESCROW-FEE) u10000))
    )
    (asserts! (is-eq (get status escrow) "pending") ERR-INVALID-STATUS)
    (asserts! (is-eq tx-sender (get buyer escrow)) ERR-NOT-AUTHORIZED)
    
    (try! (as-contract (stx-transfer? (- (get amount escrow) fee) (get seller escrow))))
    (try! (as-contract (stx-transfer? fee CONTRACT-OWNER)))
    
    (map-set escrows escrow-id
      (merge escrow { status: "completed" })
    )
    (ok true)
  )
)

;; Refund the buyer
(define-public (refund-escrow (escrow-id uint))
  (let
    (
      (escrow (unwrap! (map-get? escrows escrow-id) ERR-NOT-FOUND))
    )
    (asserts! (is-eq (get status escrow) "pending") ERR-INVALID-STATUS)
    (asserts! (is-eq tx-sender (get seller escrow)) ERR-NOT-AUTHORIZED)
    
    (try! (as-contract (stx-transfer? (get amount escrow) (get buyer escrow))))
    
    (map-set escrows escrow-id
      (merge escrow { status: "refunded" })
    )
    (ok true)
  )
)

;; Get escrow details
(define-read-only (get-escrow (escrow-id uint))
  (map-get? escrows escrow-id)
)

;; Clarinet Tests

;; Test: Create escrow
(define-public (test-create-escrow)
  (let
    (
      (buyer 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
      (amount u1000)
    )
    (try! (as-contract (contract-call? CONTRACT-NAME create-escrow buyer amount)))
    (let
      (
        (escrow (unwrap! (get-escrow u0) ERR-NOT-FOUND))
      )
      (asserts! (is-eq (get seller escrow) tx-sender) (err u1))
      (asserts! (is-eq (get buyer escrow) buyer) (err u2))
      (asserts! (is-eq (get amount escrow) amount) (err u3))
      (asserts! (is-eq (get status escrow) "pending") (err u4))
      (ok true)
    )
  )
)

;; Test: Release escrow
(define-public (test-release-escrow)
  (let
    (
      (buyer 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
      (amount u1000)
    )
    (try! (as-contract (contract-call? CONTRACT-NAME create-escrow buyer amount)))
    (try! (as-contract (contract-call? CONTRACT-NAME release-escrow u0)))
    (let
      (
        (escrow (unwrap! (get-escrow u0) ERR-NOT-FOUND))
      )
      (asserts! (is-eq (get status escrow) "completed") (err u5))
      (ok true)
    )
  )
)

;; Test: Refund escrow
(define-public (test-refund-escrow)
  (let
    (
      (buyer 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
      (amount u1000)
    )
    (try! (as-contract (contract-call? CONTRACT-NAME create-escrow buyer amount)))
    (try! (as-contract (contract-call? CONTRACT-NAME refund-escrow u0)))
    (let
      (
        (escrow (unwrap! (get-escrow u0) ERR-NOT-FOUND))
      )
      (asserts! (is-eq (get status escrow) "refunded") (err u6))
      (ok true)
    )
  )
)
