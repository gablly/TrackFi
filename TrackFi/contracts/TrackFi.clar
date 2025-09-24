;; Contract: Music Album Production Smart Contract  
;; Description: A decentralised album funding contract on Stacks. The producer sets a budget and timeline, fans fund the album, and tracks are released only if backers approve through voting. If the budget isn't met, fans can claim refunds.

;; Constants
(define-constant ERR_NOT_PRODUCER (err u100))
(define-constant ERR_ALBUM_ALREADY_STARTED (err u101))
(define-constant ERR_FAN_NOT_FOUND (err u102))
(define-constant ERR_RECORDING_FINISHED (err u103))
(define-constant ERR_BUDGET_NOT_MET (err u104))
(define-constant ERR_INSUFFICIENT_BUDGET (err u105))
(define-constant ERR_INVALID_PLEDGE (err u106))
(define-constant ERR_INVALID_TIMELINE (err u107))

;; Data Variables
(define-data-var album-producer (optional principal) none)
(define-data-var production-budget uint u0)
(define-data-var funds-collected uint u0)
(define-data-var current-track uint u0)
(define-data-var approval-votes uint u0)
(define-data-var rejection-votes uint u0)
(define-data-var total-fans uint u0)
(define-data-var recording-deadline uint u0)
(define-data-var album-status (string-ascii 20) "not_started")

;; Maps
(define-map fan-pledges principal uint)
(define-map track-list uint {title: (string-utf8 256), budget: uint})

;; Private Functions
(define-private (is-album-producer)
  (is-eq (some tx-sender) (var-get album-producer))
)

(define-private (is-recording-active)
  (and
    (is-eq (var-get album-status) "recording")
    (<= stacks-block-height (var-get recording-deadline))
  )
)

;; Public Functions
(define-public (start-album-project (budget uint) (timeline uint))
  (begin
    (asserts! (is-none (var-get album-producer)) ERR_ALBUM_ALREADY_STARTED)
    (asserts! (> budget u0) ERR_INVALID_PLEDGE)
    (asserts! (and (> timeline u0) (<= timeline u52560)) ERR_INVALID_TIMELINE)
    (var-set album-producer (some tx-sender))
    (var-set production-budget budget)
    (var-set recording-deadline (+ stacks-block-height timeline))
    (var-set album-status "recording")
    (ok true)
  )
)

(define-public (pledge-to-album (amount uint))
  (let (
    (current-pledge (default-to u0 (map-get? fan-pledges tx-sender)))
  )
    (asserts! (is-recording-active) ERR_RECORDING_FINISHED)
    (asserts! (> amount u0) ERR_INVALID_PLEDGE)
    (asserts! (<= (+ (var-get funds-collected) amount) (var-get production-budget)) ERR_BUDGET_NOT_MET)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set funds-collected (+ (var-get funds-collected) amount))
    (map-set fan-pledges tx-sender (+ current-pledge amount))
    (if (is-eq current-pledge u0)
      (var-set total-fans (+ (var-get total-fans) u1))
      true
    )
    (ok true)
  )
)

(define-public (vote-on-track (approve bool))
  (let ((pledge (default-to u0 (map-get? fan-pledges tx-sender))))
    (asserts! (> pledge u0) ERR_FAN_NOT_FOUND)
    (asserts! (is-eq (var-get album-status) "voting") ERR_NOT_PRODUCER)
    (if approve
      (var-set approval-votes (+ (var-get approval-votes) pledge))
      (var-set rejection-votes (+ (var-get rejection-votes) pledge))
    )
    (ok true)
  )
)

(define-public (initiate-track-vote)
  (begin
    (asserts! (is-album-producer) ERR_NOT_PRODUCER)
    (asserts! (is-eq (var-get album-status) "recording") ERR_NOT_PRODUCER)
    (var-set album-status "voting")
    (var-set approval-votes u0)
    (var-set rejection-votes u0)
    (ok true)
  )
)

(define-public (finalize-track-vote)
  (begin
    (asserts! (is-album-producer) ERR_NOT_PRODUCER)
    (asserts! (is-eq (var-get album-status) "voting") ERR_NOT_PRODUCER)
    (let ((total-votes (+ (var-get approval-votes) (var-get rejection-votes))))
      (asserts! (> total-votes u0) ERR_FAN_NOT_FOUND)
      (if (> (var-get approval-votes) (var-get rejection-votes))
        (begin
          (var-set current-track (+ (var-get current-track) u1))
          (var-set album-status "recording")
          (ok true)
        )
        (begin
          (var-set album-status "recording")
          (err u208)  ;; ERR_TRACK_REJECTED
        )
      )
    )
  )
)

(define-public (add-track (title (string-utf8 256)) (budget uint))
  (begin
    (asserts! (is-album-producer) ERR_NOT_PRODUCER)
    (asserts! (> budget u0) ERR_INVALID_PLEDGE)
    (asserts! (<= (len title) u256) (err u209))  ;; ERR_INVALID_TITLE
    (map-set track-list (var-get current-track) {title: title, budget: budget})
    (ok true)
  )
)

(define-public (withdraw-production-funds (amount uint))
  (begin
    (asserts! (is-album-producer) ERR_NOT_PRODUCER)
    (asserts! (> amount u0) ERR_INVALID_PLEDGE)
    (asserts! (<= amount (var-get funds-collected)) ERR_INSUFFICIENT_BUDGET)
    (as-contract (stx-transfer? amount tx-sender (unwrap! (var-get album-producer) ERR_FAN_NOT_FOUND)))
  )
)

(define-public (claim-fan-refund)
  (let ((pledge (default-to u0 (map-get? fan-pledges tx-sender))))
    (asserts! (and
      (> stacks-block-height (var-get recording-deadline))
      (< (var-get funds-collected) (var-get production-budget))
    ) ERR_NOT_PRODUCER)
    (asserts! (> pledge u0) ERR_FAN_NOT_FOUND)
    (map-delete fan-pledges tx-sender)
    (as-contract (stx-transfer? pledge tx-sender tx-sender))
  )
)

;; Read-only Functions
(define-read-only (get-album-info)
  (ok {
    producer: (var-get album-producer),
    budget: (var-get production-budget),
    collected: (var-get funds-collected),
    deadline: (var-get recording-deadline),
    status: (var-get album-status),
    current-track: (var-get current-track)
  })
)

(define-read-only (get-fan-pledge (fan principal))
  (ok (default-to u0 (map-get? fan-pledges fan)))
)

(define-read-only (get-track-details (track-id uint))
  (map-get? track-list track-id)
)