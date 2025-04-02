;; contractor-qualification.clar
;; Validates bidder capabilities

(define-data-var admin principal tx-sender)

;; Contractor data structure
(define-map contractors
  { address: principal }
  {
    name: (string-utf8 100),
    experience: uint,
    certifications: (list 10 (string-utf8 50)),
    qualified: bool
  }
)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Register as a contractor
(define-public (register-contractor
    (name (string-utf8 100))
    (experience uint)
    (certifications (list 10 (string-utf8 50))))
  (begin
    (map-set contractors
      { address: tx-sender }
      {
        name: name,
        experience: experience,
        certifications: certifications,
        qualified: false
      }
    )
    (ok true)
  )
)

;; Approve contractor qualification
(define-public (approve-contractor (contractor-address principal))
  (begin
    (asserts! (is-admin) (err u403))
    (match (map-get? contractors { address: contractor-address })
      contractor (begin
        (map-set contractors
          { address: contractor-address }
          (merge contractor { qualified: true })
        )
        (ok true)
      )
      (err u404)
    )
  )
)

;; Revoke contractor qualification
(define-public (revoke-contractor (contractor-address principal))
  (begin
    (asserts! (is-admin) (err u403))
    (match (map-get? contractors { address: contractor-address })
      contractor (begin
        (map-set contractors
          { address: contractor-address }
          (merge contractor { qualified: false })
        )
        (ok true)
      )
      (err u404)
    )
  )
)

;; Check if contractor is qualified
(define-read-only (is-qualified (contractor-address principal))
  (match (map-get? contractors { address: contractor-address })
    contractor (get qualified contractor)
    false
  )
)

;; Get contractor details
(define-read-only (get-contractor (contractor-address principal))
  (map-get? contractors { address: contractor-address })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
