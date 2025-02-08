import { describe, it, expect, beforeEach } from "vitest"

// Simulating contract state
const milestones = new Map()
const campaigns = new Map()
let milestoneIdNonce = 0

// Simulating contract functions
function createMilestone(caller: string, campaignId: number, description: string, targetAmount: number) {
  const campaign = campaigns.get(campaignId)
  if (!campaign) throw new Error("ERR_CAMPAIGN_NOT_FOUND")
  if (caller !== campaign.creator) throw new Error("ERR_NOT_AUTHORIZED")
  
  const milestoneId = milestoneIdNonce++
  const key = `${campaignId}-${milestoneId}`
  if (milestones.has(key)) throw new Error("ERR_MILESTONE_EXISTS")
  
  milestones.set(key, {
    description,
    targetAmount,
    status: "pending",
  })
  
  return milestoneId
}

function updateMilestoneStatus(caller: string, campaignId: number, milestoneId: number, newStatus: string) {
  const campaign = campaigns.get(campaignId)
  if (!campaign) throw new Error("ERR_CAMPAIGN_NOT_FOUND")
  if (caller !== campaign.creator) throw new Error("ERR_NOT_AUTHORIZED")
  
  const key = `${campaignId}-${milestoneId}`
  const milestone = milestones.get(key)
  if (!milestone) throw new Error("ERR_MILESTONE_NOT_FOUND")
  
  milestone.status = newStatus
  milestones.set(key, milestone)
  return true
}

function getMilestone(campaignId: number, milestoneId: number) {
  return milestones.get(`${campaignId}-${milestoneId}`)
}

// Helper function to set up a campaign
function setupCampaign(id: number, creator: string) {
  campaigns.set(id, { creator })
}

describe("Milestone Contract", () => {
  beforeEach(() => {
    milestones.clear()
    campaigns.clear()
    milestoneIdNonce = 0
  })
  
  it("should create a milestone", () => {
    setupCampaign(0, "user1")
    const milestoneId = createMilestone("user1", 0, "First milestone", 1000)
    expect(milestoneId).toBe(0)
    const milestone = getMilestone(0, milestoneId)
    expect(milestone.description).toBe("First milestone")
    expect(milestone.targetAmount).toBe(1000)
    expect(milestone.status).toBe("pending")
  })
  
  it("should update milestone status", () => {
    setupCampaign(0, "user1")
    const milestoneId = createMilestone("user1", 0, "First milestone", 1000)
    expect(updateMilestoneStatus("user1", 0, milestoneId, "completed")).toBe(true)
    const milestone = getMilestone(0, milestoneId)
    expect(milestone.status).toBe("completed")
  })
  
  it("should not create milestone for non-existent campaign", () => {
    expect(() => createMilestone("user1", 999, "Invalid milestone", 1000)).toThrow("ERR_CAMPAIGN_NOT_FOUND")
  })
  
  it("should not allow unauthorized milestone creation", () => {
    setupCampaign(0, "user1")
    expect(() => createMilestone("user2", 0, "Unauthorized milestone", 1000)).toThrow("ERR_NOT_AUTHORIZED")
  })
  
  it("should not allow unauthorized milestone status update", () => {
    setupCampaign(0, "user1")
    const milestoneId = createMilestone("user1", 0, "First milestone", 1000)
    expect(() => updateMilestoneStatus("user2", 0, milestoneId, "completed")).toThrow("ERR_NOT_AUTHORIZED")
  })
})

