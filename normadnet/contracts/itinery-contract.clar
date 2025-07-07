;; Travel Guide Community Contract
;; A platform for travel experts to share experiences, certifications, and destination expertise

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-GUIDE-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-ENDORSED (err u102))
(define-constant ERR-INVALID-PRIVACY-LEVEL (err u103))
(define-constant ERR-CERTIFICATION-NOT-FOUND (err u104))

;; Privacy levels
(define-constant PRIVACY-PUBLIC u0)
(define-constant PRIVACY-GUIDE-NETWORK u1)
(define-constant PRIVACY-PRIVATE u2)

;; Data structures
(define-map guide-profiles
  principal
  {
    guide-name: (string-ascii 50),
    bio: (string-ascii 500),
    specialization-regions: (string-ascii 200),
    privacy-level: uint,
    joined-at: uint,
    is-verified: bool
  })

(define-map travel-experiences
  { guide: principal, experience-id: uint }
  {
    destination-name: (string-ascii 100),
    trip-type: (string-ascii 100),
    visit-date: uint,
    duration: (optional uint),
    experience-description: (string-ascii 500),
    privacy-level: uint
  })

(define-map destination-certifications
  { guide: principal, certification-id: uint }
  {
    certification-name: (string-ascii 100),
    issuing-organization: (string-ascii 100),
    issue-date: uint,
    expiry-date: (optional uint),
    certification-url: (string-ascii 200),
    privacy-level: uint,
    is-verified: bool
  })

(define-map expertise-endorsements
  { endorser: principal, endorsee: principal, expertise: (string-ascii 50) }
  {
    endorsement-review: (string-ascii 200),
    timestamp: uint,
    is-public: bool
  })

(define-map guide-connections
  { guide1: principal, guide2: principal }
  {
    status: (string-ascii 20), ;; "pending", "accepted", "blocked"
    initiated-by: principal,
    timestamp: uint
  })

;; Counters for unique IDs
(define-data-var experience-id-counter uint u0)
(define-data-var certification-id-counter uint u0)

;; Contract owner
(define-data-var contract-owner principal tx-sender)

;; Guide profile management functions
(define-public (create-guide-profile (guide-name (string-ascii 50)) (bio (string-ascii 500)) (specialization-regions (string-ascii 200)) (privacy-level uint))
  (begin
    (asserts! (<= privacy-level PRIVACY-PRIVATE) ERR-INVALID-PRIVACY-LEVEL)
    (ok (map-set guide-profiles tx-sender {
      guide-name: guide-name,
      bio: bio,
      specialization-regions: specialization-regions,
      privacy-level: privacy-level,
      joined-at: block-height,
      is-verified: false
    }))))

(define-public (update-guide-profile (guide-name (string-ascii 50)) (bio (string-ascii 500)) (specialization-regions (string-ascii 200)) (privacy-level uint))
  (begin
    (asserts! (<= privacy-level PRIVACY-PRIVATE) ERR-INVALID-PRIVACY-LEVEL)
    (asserts! (is-some (map-get? guide-profiles tx-sender)) ERR-GUIDE-NOT-FOUND)
    (ok (map-set guide-profiles tx-sender {
      guide-name: guide-name,
      bio: bio,
      specialization-regions: specialization-regions,
      privacy-level: privacy-level,
      joined-at: (default-to block-height (get joined-at (map-get? guide-profiles tx-sender))),
      is-verified: (default-to false (get is-verified (map-get? guide-profiles tx-sender)))
    }))))

;; Travel experience functions
(define-public (add-travel-experience (destination-name (string-ascii 100)) (trip-type (string-ascii 100)) (visit-date uint) (duration (optional uint)) (experience-description (string-ascii 500)) (privacy-level uint))
  (let ((experience-id (+ (var-get experience-id-counter) u1)))
    (begin
      (asserts! (<= privacy-level PRIVACY-PRIVATE) ERR-INVALID-PRIVACY-LEVEL)
      (asserts! (is-some (map-get? guide-profiles tx-sender)) ERR-GUIDE-NOT-FOUND)
      (var-set experience-id-counter experience-id)
      (ok (map-set travel-experiences { guide: tx-sender, experience-id: experience-id } {
        destination-name: destination-name,
        trip-type: trip-type,
        visit-date: visit-date,
        duration: duration,
        experience-description: experience-description,
        privacy-level: privacy-level
      })))))

;; Destination certification functions
(define-public (add-destination-certification (certification-name (string-ascii 100)) (issuing-organization (string-ascii 100)) (issue-date uint) (expiry-date (optional uint)) (certification-url (string-ascii 200)) (privacy-level uint))
  (let ((certification-id (+ (var-get certification-id-counter) u1)))
    (begin
      (asserts! (<= privacy-level PRIVACY-PRIVATE) ERR-INVALID-PRIVACY-LEVEL)
      (asserts! (is-some (map-get? guide-profiles tx-sender)) ERR-GUIDE-NOT-FOUND)
      (var-set certification-id-counter certification-id)
      (ok (map-set destination-certifications { guide: tx-sender, certification-id: certification-id } {
        certification-name: certification-name,
        issuing-organization: issuing-organization,
        issue-date: issue-date,
        expiry-date: expiry-date,
        certification-url: certification-url,
        privacy-level: privacy-level,
        is-verified: false
      })))))

(define-public (verify-destination-certification (guide principal) (certification-id uint))
  (let ((certification (map-get? destination-certifications { guide: guide, certification-id: certification-id })))
    (begin
      (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
      (asserts! (is-some certification) ERR-CERTIFICATION-NOT-FOUND)
      (ok (map-set destination-certifications { guide: guide, certification-id: certification-id }
        (merge (unwrap-panic certification) { is-verified: true }))))))

;; Expertise endorsement functions
(define-public (endorse-travel-expertise (endorsee principal) (expertise (string-ascii 50)) (endorsement-review (string-ascii 200)) (is-public bool))
  (begin
    (asserts! (is-some (map-get? guide-profiles tx-sender)) ERR-GUIDE-NOT-FOUND)
    (asserts! (is-some (map-get? guide-profiles endorsee)) ERR-GUIDE-NOT-FOUND)
    (asserts! (is-none (map-get? expertise-endorsements { endorser: tx-sender, endorsee: endorsee, expertise: expertise })) ERR-ALREADY-ENDORSED)
    (ok (map-set expertise-endorsements { endorser: tx-sender, endorsee: endorsee, expertise: expertise } {
      endorsement-review: endorsement-review,
      timestamp: block-height,
      is-public: is-public
    }))))

;; Guide connection functions
(define-public (send-guide-network-invite (to-guide principal))
  (begin
    (asserts! (is-some (map-get? guide-profiles tx-sender)) ERR-GUIDE-NOT-FOUND)
    (asserts! (is-some (map-get? guide-profiles to-guide)) ERR-GUIDE-NOT-FOUND)
    (ok (map-set guide-connections { guide1: tx-sender, guide2: to-guide } {
      status: "pending",
      initiated-by: tx-sender,
      timestamp: block-height
    }))))

(define-public (accept-guide-network-invite (from-guide principal))
  (let ((connection (map-get? guide-connections { guide1: from-guide, guide2: tx-sender })))
    (begin
      (asserts! (is-some connection) ERR-GUIDE-NOT-FOUND)
      (asserts! (is-eq (get status (unwrap-panic connection)) "pending") ERR-NOT-AUTHORIZED)
      (ok (map-set guide-connections { guide1: from-guide, guide2: tx-sender }
        (merge (unwrap-panic connection) { status: "accepted" }))))))

;; Read-only functions with privacy controls
(define-read-only (get-guide-profile (guide principal))
  (let ((profile (map-get? guide-profiles guide)))
    (if (is-some profile)
      (let ((profile-data (unwrap-panic profile)))
        (if (or (is-eq (get privacy-level profile-data) PRIVACY-PUBLIC)
                (is-eq guide tx-sender)
                (is-guide-connected guide tx-sender))
          profile
          none))
      none)))

(define-read-only (get-travel-experience (guide principal) (experience-id uint))
  (let ((experience (map-get? travel-experiences { guide: guide, experience-id: experience-id })))
    (if (is-some experience)
      (let ((experience-data (unwrap-panic experience)))
        (if (can-view-guide-data guide (get privacy-level experience-data))
          experience
          none))
      none)))

(define-read-only (get-destination-certification (guide principal) (certification-id uint))
  (let ((certification (map-get? destination-certifications { guide: guide, certification-id: certification-id })))
    (if (is-some certification)
      (let ((certification-data (unwrap-panic certification)))
        (if (can-view-guide-data guide (get privacy-level certification-data))
          certification
          none))
      none)))

(define-read-only (get-expertise-endorsement (endorser principal) (endorsee principal) (expertise (string-ascii 50)))
  (let ((endorsement (map-get? expertise-endorsements { endorser: endorser, endorsee: endorsee, expertise: expertise })))
    (if (is-some endorsement)
      (let ((endorsement-data (unwrap-panic endorsement)))
        (if (or (get is-public endorsement-data)
                (is-eq endorsee tx-sender)
                (is-guide-connected endorsee tx-sender))
          endorsement
          none))
      none)))

;; Helper functions
(define-read-only (is-guide-connected (guide1 principal) (guide2 principal))
  (or (is-eq (get status (default-to { status: "none", initiated-by: guide1, timestamp: u0 } 
                          (map-get? guide-connections { guide1: guide1, guide2: guide2 }))) "accepted")
      (is-eq (get status (default-to { status: "none", initiated-by: guide2, timestamp: u0 } 
                          (map-get? guide-connections { guide1: guide2, guide2: guide1 }))) "accepted")))

(define-read-only (can-view-guide-data (data-owner principal) (privacy-level uint))
  (or (is-eq privacy-level PRIVACY-PUBLIC)
      (is-eq data-owner tx-sender)
      (and (is-eq privacy-level PRIVACY-GUIDE-NETWORK) (is-guide-connected data-owner tx-sender))))

;; Admin functions
(define-public (verify-guide-profile (guide principal))
  (let ((profile (map-get? guide-profiles guide)))
    (begin
      (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
      (asserts! (is-some profile) ERR-GUIDE-NOT-FOUND)
      (ok (map-set guide-profiles guide
        (merge (unwrap-panic profile) { is-verified: true }))))))

(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set contract-owner new-owner)))) 