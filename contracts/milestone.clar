;; Milestone Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_CAMPAIGN_NOT_FOUND (err u101))
(define-constant ERR_MILESTONE_EXISTS (err u102))
(define-constant ERR_MILESTONE_NOT_FOUND (err u103))

;; Data Maps
(define-map milestones
  { campaign-id: uint, milestone-id: uint }
  {
    description: (string-ascii 256),
    target-amount: uint,
    status: (string-ascii 20)
  }
)

(define-map campaigns
  { id: uint }
  { creator: principal }
)

;; Data Variables
(define-data-var milestone-id-nonce uint u0)

;; Public Functions
(define-public (create-milestone (campaign-id uint) (description (string-ascii 256)) (target-amount uint))
  (let
    (
      (milestone-id (var-get milestone-id-nonce))
      (campaign (unwrap! (map-get? campaigns { id: campaign-id }) ERR_CAMPAIGN_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get creator campaign)) ERR_NOT_AUTHORIZED)
    (asserts! (is-none (map-get? milestones { campaign-id: campaign-id, milestone-id: milestone-id })) ERR_MILESTONE_EXISTS)
    (map-set milestones
      { campaign-id: campaign-id, milestone-id: milestone-id }
      {
        description: description,
        target-amount: target-amount,
        status: "pending"
      }
    )
    (var-set milestone-id-nonce (+ milestone-id u1))
    (ok milestone-id)
  )
)

(define-public (update-milestone-status (campaign-id uint) (milestone-id uint) (new-status (string-ascii 20)))
  (let
    (
      (milestone (unwrap! (map-get? milestones { campaign-id: campaign-id, milestone-id: milestone-id }) ERR_MILESTONE_NOT_FOUND))
      (campaign (unwrap! (map-get? campaigns { id: campaign-id }) ERR_CAMPAIGN_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get creator campaign)) ERR_NOT_AUTHORIZED)
    (ok (map-set milestones
      { campaign-id: campaign-id, milestone-id: milestone-id }
      (merge milestone { status: new-status })
    ))
  )
)

;; Read-only Functions
(define-read-only (get-milestone (campaign-id uint) (milestone-id uint))
  (map-get? milestones { campaign-id: campaign-id, milestone-id: milestone-id })
)

