model "IAM"

persona User
persona HouseholdViewer

context User
context Household

slice "Sign Up" {
  ui Authentication Screen @User
  command Sign Up public {
    provider: string
    providerSubject: string
    verifiedEmail: string
    displayName: string
    authenticationRequestId: string
  } note "slices/sign-up.md"
  event User Account Created @User public {
    id: uuid assigned
    provider: string
    providerSubject: string
    verifiedEmail: string
    createdAt: datetime assigned
    authenticationRequestId: string
  }
}

slice "Authenticate" {
  ui Authentication Screen @User
  command Authenticate public {
    provider: string
    providerSubject: string
    authenticationRequestId: string
  } note "slices/authenticate.md"
  event User Authenticated @User public {
    id: uuid assigned
    provider: string
    authenticatedAt: datetime assigned
    authenticationRequestId: string
  }
}

slice "Create Initial Household" {
  ui Household Setup Screen @User
  command Create Initial Household public {
    userId: uuid
    name: string
  } note "slices/create-initial-household.md"
  event Household Created @Household public {
    id: uuid assigned
    name: string
    rootManagerId: uuid assigned
    createdAt: datetime assigned
  }
}

slice "View Current Household" {
  view Current Household public from "Household Created" {
    id: uuid
    name: string
    role: string derived
  } note "slices/view-current-household.md"
  ui Household Screen @User
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
