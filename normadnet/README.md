# NomadNet 🧭

**NomadNet** is a decentralized travel guide community platform built with Clarity smart contracts on the Stacks blockchain. It empowers travel experts to share experiences, manage certifications, and build trusted networks of endorsed guides.

---

## ✨ Features

- **Guide Profiles**  
  Travel experts can create, update, and manage detailed personal profiles with bio, regional specialization, and privacy preferences.

- **Experience Sharing**  
  Upload travel experiences (destinations, trip types, durations, reviews) with selectable visibility: public, network-only, or private.

- **Certifications Management**  
  Record destination-specific certifications with issuer info and URLs. Admins can verify these certifications for added credibility.

- **Expertise Endorsements**  
  Peer-to-peer endorsements of travel skills and regional expertise. Endorsements can be public or limited to network connections.

- **Private Networking**  
  Travel guides can send, accept, or block connection requests to grow their verified professional network.

- **Privacy Controls**  
  All profile, experience, and certification data supports three-tiered access: `Public`, `Guide Network`, or `Private`.

---

## 🔐 Access Control and Privacy Levels

| Level             | Description                              |
|------------------|------------------------------------------|
| `Public`          | Visible to everyone                      |
| `Guide Network`   | Only visible to connected guides         |
| `Private`         | Only visible to the guide themself       |

---

## 🛠️ Smart Contract Structure

- `guide-profiles` – Stores profiles for all guides
- `travel-experiences` – Logs travel-related experiences
- `destination-certifications` – Tracks guide certifications
- `expertise-endorsements` – Endorsements of skills and expertise
- `guide-connections` – Relationships and connection status between guides

---

## 🧑‍💼 Admin Functions

Only the `contract-owner` can:
- Verify guide profiles
- Verify destination certifications
- Transfer contract ownership

---

## 📦 Deployment Notes

- Ensure Clarity runtime environment (e.g., [Clarinet](https://docs.stacks.co/write-smart-contracts/clarinet) or testnet deployment)
- Contract owner is initialized as the deployer (`tx-sender`)
- `experience-id-counter` and `certification-id-counter` are used to ensure unique entries

## ✅ To-Do & Enhancements

- Add experience and certification deletion
- Introduce reputation scoring based on endorsements
- Implement event tracking for auditability
- UI/UX interface for NomadNet community platform
