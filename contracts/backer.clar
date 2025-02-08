;; Backer Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_CAMPAIGN_NOT_FOUND (err u101))
(define-constant ERR_INVALID_AMOUNT (err u102))

;; Data Maps
(define-map contributions
  { campaign-id: uint, backer: principal }
  { amount: uint }
)

(define-map campaigns
  { id: uint }
  { status: (string-ascii 20) }
)

;; Public Functions
(define-public (contribute (campaign-id uint) (amount uint))
  (let
    (
      (campaign (unwrap! (map-get? campaigns { id: campaign-id }) ERR_CAMPAIGN_NOT_FOUND))
      (current-contribution (default-to u0 (get amount (map-get? contributions { campaign-id: campaign-id, backer: tx-sender }))))
    )
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (is-eq (get status campaign) "active") ERR_NOT_AUTHORIZED)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set contributions
      { campaign-id: campaign-id, backer: tx-sender }
      { amount: (+ current-contribution amount) }
    )
    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-contribution (campaign-id uint) (backer principal))
  (default-to u0 (get amount (map-get? contributions { campaign-id: campaign-id, backer: backer })))
)

