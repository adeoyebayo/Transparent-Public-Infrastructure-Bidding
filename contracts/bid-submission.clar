;; bid-submission.clar
;; Securely records and seals proposal details

(define-data-var admin principal tx-sender)

;; Bid data structure
(define-map bids
  { project-id: uint, bidder: principal }
  {
    amount: uint,
    proposal: (string-utf8 2000),
    timeline: uint,
    timestamp: uint,
    hash: (buff 32)
  }
)

;; Project bids tracking
(define-map project-bidders
  { project-id: uint }
  { bidders: (list 100 principal) }
)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Define contract principals
(define-constant contract-owner tx-sender)
(define-constant project-specification-contract (as-contract contract-owner))
(define-constant contractor-qualification-contract (as-contract contract-owner))

;; Submit a bid for a project
(define-public (submit-bid
    (project-id uint)
    (amount uint)
    (proposal (string-utf8 2000))
    (timeline uint))
  (let (
    (bidder tx-sender)
    (timestamp (unwrap-panic (get-block-info? time (- block-height u1))))
    (proposal-hash (sha256 (concat (concat (concat
      (unwrap-panic (to-consensus-buff? amount))
      (unwrap-panic (to-consensus-buff? proposal)))
      (unwrap-panic (to-consensus-buff? timeline)))
      (unwrap-panic (to-consensus-buff? timestamp)))))
  )
    ;; Check if bidder is qualified
    (asserts! (is-qualified bidder) (err u401))

    ;; Check if project exists and is open
    (asserts! (is-project-open project-id) (err u403))

    ;; Store the bid
    (map-set bids
      { project-id: project-id, bidder: bidder }
      {
        amount: amount,
        proposal: proposal,
        timeline: timeline,
        timestamp: timestamp,
        hash: proposal-hash
      }
    )

    ;; Add bidder to project bidders list
    (match (map-get? project-bidders { project-id: project-id })
      existing-data (map-set project-bidders
        { project-id: project-id }
        { bidders: (unwrap-panic (as-max-len? (append (get bidders existing-data) bidder) u100)) }
      )
      (map-set project-bidders
        { project-id: project-id }
        { bidders: (list bidder) }
      )
    )

    (ok true)
  )
)

;; Check if bidder is qualified (internal function)
(define-private (is-qualified (bidder principal))
  ;; For development, we'll return true
  ;; In production, this would call the contractor-qualification contract
  true
)

;; Check if project is open (internal function)
(define-private (is-project-open (project-id uint))
  ;; For development, we'll return true
  ;; In production, this would call the project-specification contract
  true
)

;; Get bid details
(define-read-only (get-bid (project-id uint) (bidder principal))
  (map-get? bids { project-id: project-id, bidder: bidder })
)

;; Get all bidders for a project
(define-read-only (get-project-bidders (project-id uint))
  (match (map-get? project-bidders { project-id: project-id })
    data (get bidders data)
    (list)
  )
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
