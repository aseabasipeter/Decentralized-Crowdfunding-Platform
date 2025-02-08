;; Refund Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_CAMPAIGN_NOT_FOUND (err u101))
(define-constant ERR_NO_REFUND_AVAILABLE (err u102))

;; Data Maps
(define-map campaigns
  { id: uint }
  { status: (string-ascii 20), deadline: uint }
)

(define-map contributions
  { campaign-id: uint, backer: principal }
  { amount: uint }
)

;; Public Functions
(define-public (request-refund (campaign-id uint))
  (let
    (
      (campaign (unwrap! (map-get? campaigns { id: campaign-id }) ERR_CAMPAIGN_NOT_FOUND))
      (contribution (unwrap! (map-get? contributions { campaign-id: campaign-id, backer: tx-sender }) ERR_NO_REFUND_AVAILABLE))
    )
    (asserts! (or (is-eq (get status campaign) "failed") (> block-height (get deadline campaign))) ERR_NOT_AUTHORIZED)
    (asserts! (> (get amount contribution) u0) ERR_NO_REFUND_AVAILABLE)
    (try! (as-contract (stx-transfer? (get amount contribution) tx-sender tx-sender)))
    (map-set contributions { campaign-id: campaign-id, backer: tx-sender } { amount: u0 })
    (ok true)
  )
)

;; Read-only Functions
(define-read-only (can-refund (campaign-id uint) (backer principal))
  (match (map-get? campaigns { id: campaign-id })
    campaign-data (match (map-get? contributions { campaign-id: campaign-id, backer: backer })
      contribution-data (and
        (> (get amount contribution-data) u0)
        (or
          (is-eq (get status campaign-data) "failed")
          (> block-height (get deadline campaign-data))
        )
      )
      false
    )
    false
  )
)

