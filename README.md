# Music Album Production Smart Contract

A decentralized album funding and production contract built on the Stacks blockchain. This smart contract enables music producers to crowdfund album production while giving fans voting rights on track releases.

## Overview

The contract facilitates a transparent, community-driven music production process where:
- **Producers** set budgets and timelines for album production
- **Fans** contribute funds and vote on track approvals
- **Tracks** are released only after community approval
- **Refunds** are available if funding goals aren't met

## Features

### **Producer Functions**
- Start album projects with custom budgets and timelines
- Add tracks with individual budgets
- Initiate and finalize community votes on tracks
- Withdraw production funds for approved tracks

### **Fan Functions**
- Pledge funds to support album production
- Vote on track releases (weighted by contribution amount)
- Claim refunds if project fails to meet funding goals

### **Transparency**
- Public album information and statistics
- Track-by-track budget breakdown
- Real-time funding progress
- Community voting results

## Contract States

| Status | Description |
|--------|-------------|
| `not_started` | Initial state, no producer assigned |
| `recording` | Active funding period, fans can pledge |
| `voting` | Community voting on current track |

## Public Functions

### Producer Functions

#### `start-album-project`
```clarity
(start-album-project (budget uint) (timeline uint))
```
Initializes a new album project.
- `budget`: Total funding goal in microSTX
- `timeline`: Project duration in blocks (max 1 year ≈ 52,560 blocks)

#### `add-track`
```clarity
(add-track (title (string-utf8 256)) (budget uint))
```
Adds a new track to the album.
- `title`: Track title (max 256 characters)
- `budget`: Individual track budget

#### `initiate-track-vote`
```clarity
(initiate-track-vote)
```
Starts community voting on the current track.

#### `finalize-track-vote`
```clarity
(finalize-track-vote)
```
Concludes voting and processes results.

#### `withdraw-production-funds`
```clarity
(withdraw-production-funds (amount uint))
```
Allows producer to withdraw funds for production costs.

### Fan Functions

#### `pledge-to-album`
```clarity
(pledge-to-album (amount uint))
```
Contribute funds to the album project.
- `amount`: Pledge amount in microSTX

#### `vote-on-track`
```clarity
(vote-on-track (approve bool))
```
Vote on current track release.
- `approve`: true to approve, false to reject
- Voting power is weighted by pledge amount

#### `claim-fan-refund`
```clarity
(claim-fan-refund)
```
Claim refund if project deadline passed without meeting funding goal.

## Read-Only Functions

#### `get-album-info`
Returns comprehensive album project information:
```clarity
{
  producer: (optional principal),
  budget: uint,
  collected: uint,
  deadline: uint,
  status: (string-ascii 20),
  current-track: uint
}
```

#### `get-fan-pledge`
```clarity
(get-fan-pledge (fan principal))
```
Returns pledge amount for a specific fan.

#### `get-track-details`
```clarity
(get-track-details (track-id uint))
```
Returns track information including title and budget.

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | `ERR_NOT_PRODUCER` | Caller is not the album producer |
| u101 | `ERR_ALBUM_ALREADY_STARTED` | Album project already exists |
| u102 | `ERR_FAN_NOT_FOUND` | Fan has no pledge record |
| u103 | `ERR_RECORDING_FINISHED` | Recording period has ended |
| u104 | `ERR_BUDGET_NOT_MET` | Funding goal not reached |
| u105 | `ERR_INSUFFICIENT_BUDGET` | Not enough funds for withdrawal |
| u106 | `ERR_INVALID_PLEDGE` | Invalid pledge amount (must be > 0) |
| u107 | `ERR_INVALID_TIMELINE` | Invalid timeline (must be 1-52560 blocks) |
| u208 | `ERR_TRACK_REJECTED` | Community rejected the track |
| u209 | `ERR_INVALID_TITLE` | Track title exceeds length limit |

## Usage Example

### 1. Producer Starts Project
```clarity
(contract-call? .album-contract start-album-project u1000000 u10000)
;; Start project with 1 STX budget, 10,000 block timeline
```

### 2. Producer Adds Tracks
```clarity
(contract-call? .album-contract add-track u"Opening Theme" u100000)
(contract-call? .album-contract add-track u"Love Ballad" u150000)
```

### 3. Fans Pledge Support
```clarity
(contract-call? .album-contract pledge-to-album u250000)
;; Fan pledges 0.25 STX
```

### 4. Community Voting
```clarity
;; Producer initiates vote
(contract-call? .album-contract initiate-track-vote)

;; Fans vote (weighted by pledge amount)
(contract-call? .album-contract vote-on-track true)

;; Producer finalizes vote
(contract-call? .album-contract finalize-track-vote)
```

## Security Features

- **Access Control**: Only producers can manage projects and withdraw funds
- **Deadline Protection**: Automatic refund eligibility after deadline
- **Budget Limits**: Prevents over-pledging beyond project budget
- **Voting Rights**: Only contributing fans can vote
- **Refund Mechanism**: Guaranteed refunds for failed projects

## Timeline Considerations

- **Block Time**: ~10 minutes per block on Stacks
- **Maximum Timeline**: 52,560 blocks ≈ 1 year
- **Refund Window**: Available after deadline if budget not met

