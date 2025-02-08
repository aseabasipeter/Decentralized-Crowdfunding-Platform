import { describe, it, expect, beforeEach } from "vitest"

// Simulating contract state
const campaigns = new Map()
const contributions = new Map()

// Simulating contract functions
function requestRefund(caller: string, campaignId: number) {
  const campaign = campaigns.get(campaignId)
  if (!campaign) throw new Error("ERR_CAMPAIGN_NOT_FOUND")
  
  const key = `${campaignId}-${caller}`
  const contribution = contributions.get(key) || 0
  if (contribution === 0) throw new Error("ERR_NO_REFUND_AVAILABLE")
  
  if (campaign.status !== "failed" && campaign.deadline > Date.now()) {
    throw new Error("ERR_NOT_AUTHORIZED")
  }
  
  // Process refund
  contributions.set(key, 0)
  campaign.raised -= contribution
  campaigns.set(campaignId, campaign)
  
  return contribution
}

function canRefund(campaignId: number, backer: string) {
  const campaign = campaigns.get(campaignId)
  if (!campaign) return false
  
  const contribution = contributions.get(`${campaignId}-${backer}`) || 0
  
  return contribution > 0 && (campaign.status === "failed" || campaign.deadline <= Date.now())
}

// Helper functions to set up test scenarios
function setupCampaign(id: number, status: string, deadline: number) {
  campaigns.set(id, { status, deadline, raised: 0 })
}

function setupContribution(campaignId: number, backer: string, amount: number) {
  const key = `${campaignId}-${backer}`
  contributions.set(key, amount)
  const campaign = campaigns.get(campaignId)
  campaign.raised += amount
  campaigns.set(campaignId, campaign)
}

describe("Refund Contract", () => {
  beforeEach(() => {
    campaigns.clear()
    contributions.clear()
  })
  
  it("should allow refund for failed campaign", () => {
    setupCampaign(0, "failed", Date.now() + 86400000)
    setupContribution(0, "user1", 100)
    expect(requestRefund("user1", 0)).toBe(100)
    expect(contributions.get("0-user1")).toBe(0)
  })
  
  it("should allow refund for expired campaign", () => {
    setupCampaign(0, "active", Date.now() - 86400000)
    setupContribution(0, "user1", 100)
    expect(requestRefund("user1", 0)).toBe(100)
    expect(contributions.get("0-user1")).toBe(0)
  })
  
  it("should not allow refund for active and non-expired campaign", () => {
    setupCampaign(0, "active", Date.now() + 86400000)
    setupContribution(0, "user1", 100)
    expect(() => requestRefund("user1", 0)).toThrow("ERR_NOT_AUTHORIZED")
  })
  
  it("should not allow refund for non-existent campaign", () => {
    expect(() => requestRefund("user1", 999)).toThrow("ERR_CAMPAIGN_NOT_FOUND")
  })
  
  it("should not allow refund when no contribution was made", () => {
    setupCampaign(0, "failed", Date.now())
    expect(() => requestRefund("user1", 0)).toThrow("ERR_NO_REFUND_AVAILABLE")
  })
  
  it("should correctly determine if refund is possible", () => {
    setupCampaign(0, "failed", Date.now())
    setupContribution(0, "user1", 100)
    expect(canRefund(0, "user1")).toBe(true)
    
    setupCampaign(1, "active", Date.now() + 86400000)
    setupContribution(1, "user1", 100)
    expect(canRefund(1, "user1")).toBe(false)
    
    setupCampaign(2, "active", Date.now() - 86400000)
    setupContribution(2, "user1", 100)
    expect(canRefund(2, "user1")).toBe(true)
  })
})

