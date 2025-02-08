;; Refund Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_CAMPAIGN_NOT_FOUND (err u101))
(define-constant ERR_NO_REFUND_AVAILABLE (err u102))

;; Public Functions
(define-public (request-refund (campaign-id uint))
  (let
    (
      (campaign (unwrap! (contract-call? .campaign get-campaign campaign-id) ERR_CAMPAIGN_NOT_FOUND))
      (contribution (unwrap! (contract-call? .backer get-contribution campaign-id tx-sender) ERR_NO_REFUND_AVAILABLE))
    )
    (asserts! (or (is-eq (get status campaign) "failed") (> block-height (get deadline campaign))) ERR_NOT_AUTHORIZED)
    (asserts! (> contribution u0) ERR_NO_REFUND_AVAILABLE)
    (try! (as-contract (stx-transfer? contribution tx-sender tx-sender)))
    (contract-call? .backer contribute campaign-id u0)
  )
)

;; Read-only Functions
(define-read-only (can-refund (campaign-id uint) (backer principal))
  (let
    (
      (campaign (unwrap! (contract-call? .campaign get-campaign campaign-id) false))
      (contribution (contract-call? .backer get-contribution campaign-id backer))
    )
    (and
      (is-some campaign)
      (> contribution u0)
      (or
        (is-eq (get status campaign) "failed")
        (> block-height (get deadline campaign))
      )
    )
  )
)

