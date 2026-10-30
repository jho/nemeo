model "IAM"

persona User
persona HouseholdViewer

context User
context Household

slice "Sign Up" {
  ui Authentication Screen @User
  command Sign Up note "slices/sign-up.md"
  event User Account Created @User
}

slice "Authenticate" {
  ui Authentication Screen @User
  command Authenticate note "slices/authenticate.md"
  event User Authenticated @User
}

slice "Create Initial Household" {
  ui Household Setup Screen @User
  command Create Initial Household note "slices/create-initial-household.md"
  event Household Created @Household
}

slice "Invite Household Viewer" {
  ui Household Access Screen @User
  command Invite Household Viewer
  event Household Viewer Invited @Household
}

slice "Review Household Invitation" {
  view Pending Household Invitations from "Household Viewer Invited"
  ui Invitation Screen @User
}

slice "Accept Household Invitation" {
  ui Invitation Screen @HouseholdViewer
  command Accept Household Invitation
  event Household Viewer Added @Household
}

slice "Household Access" {
  view Household Members from "Household Created", "Household Viewer Invited", "Household Viewer Added"
  ui Household Access Screen @User
}

slice "Start Household Setup" {
  view Household Setup Status from "User Account Created", "User Authenticated" note "slices/start-household-setup.md"
  ui Household Setup Screen @User
}
