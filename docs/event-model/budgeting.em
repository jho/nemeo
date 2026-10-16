model "Nemeo MVP"

persona User
persona HouseholdViewer
persona Agent

context Identity
context UserProfile
context Household
context Connections
context Accounts
context Transactions
context Categorization
context Transfers
context Budget
context Reporting
context MCP

# MVP happy path: sign up, connect, import, prepare, review, and understand pace.

slice "Sign Up with Google" {
  ui Google Sign-in Screen @User
  command Sign Up with Google note "slices/sign-up-with-google.md"
  event User Account Created @UserProfile
}

slice "Authenticate with Google" {
  ui Google Sign-in Screen @User
  command Authenticate with Google note "slices/authenticate-with-google.md"
  event User Authenticated @Identity
}

slice "Start Household Setup" {
  view Household Setup Status from "User Account Created", "User Authenticated"
  ui Household Setup Screen @User
}

slice "Create Initial Household" {
  ui Household Setup Confirmation @User
  command Create Initial Household note "slices/create-initial-household.md"
  event Household Created @Household
}
arrow Household Setup Screen -> Create Initial Household

slice "Start Budget Setup" {
  view Setup Status from "Household Created"
  ui Budget Setup Screen @User
}

slice "Connect SimpleFIN" {
  ui Provider Connection Screen @User
  command Connect SimpleFIN
  event SimpleFIN Connection Established @Connections
}

slice "Discover Provider Accounts" {
  view Discovered Accounts from "SimpleFIN Connection Established"
  translation SimpleFIN Account Discovery
}

slice "Select Accounts for Budget" {
  ui Account Selection Screen @User
  command Select Budget Accounts
  event Budget Accounts Selected @Accounts
}
arrow SimpleFIN Account Discovery -> Select Budget Accounts

slice "Create Initial Budget" {
  command Create Initial Budget
  event Initial Budget Created @Budget
}
arrow Account Selection Screen -> Create Initial Budget

slice "Initialize Budget Categories" {
  view Category Initialization Inputs from "Initial Budget Created"
  processor Category Taxonomy Initializer
}

slice "Record Initial Category Taxonomy" {
  command Initialize Budget Categories
  event Budget Categories Initialized @Budget
}
arrow Category Taxonomy Initializer -> Initialize Budget Categories

slice "Schedule Provider Sync" {
  view Syncable Connections from "SimpleFIN Connection Established", "Budget Accounts Selected"
  processor Sync Scheduler
}

slice "Start Provider Sync" {
  command Start Provider Sync
  event Provider Sync Started @Connections
}
arrow Sync Scheduler -> Start Provider Sync

slice "Request SimpleFIN Data" {
  view Pending Provider Sync from "Provider Sync Started"
  translation SimpleFIN Data Adapter
}

slice "Receive Provider Data" {
  command Receive Provider Data
  event Provider Data Received @Connections
}
arrow SimpleFIN Data Adapter -> Receive Provider Data

slice "Receive Provider Sync Failure" {
  command Record Provider Sync Failure
  event Provider Sync Failed @Connections
}
arrow SimpleFIN Data Adapter -> Record Provider Sync Failure

slice "Normalize Provider Data" {
  view Received Provider Data from "Provider Data Received"
  processor Provider Data Normalizer
}

slice "Import Accounts and Transactions" {
  command Import Provider Records
  event Provider Records Imported @Accounts
}
arrow Provider Data Normalizer -> Import Provider Records

slice "Reconcile Account Balances" {
  view Balance Reconciliation Worklist from "Provider Records Imported"
  processor Balance Reconciler
}

slice "Record Opening Balance" {
  command Record Opening Balance
  event Opening Balance Recorded @Accounts
}
arrow Balance Reconciler -> Record Opening Balance

slice "Review Imported Transactions" {
  view Imported Transactions from "Provider Records Imported", "Opening Balance Recorded"
  ui Transactions Screen @User
}

slice "Find Transactions to Categorize" {
  view Transactions Needing Categories from "Provider Records Imported"
  processor Categorization Automation
}

slice "Categorize Transactions Automatically" {
  command Categorize Transactions
  event Transactions Categorized @Categorization
}
arrow Categorization Automation -> Categorize Transactions

slice "Find Transfer Candidates" {
  view Transfer Candidates from "Transactions Categorized"
  processor Transfer Matching Automation
}

slice "Suggest Transfer Match" {
  command Suggest Transfer Match
  event Transfer Match Suggested @Transfers
}
arrow Transfer Matching Automation -> Suggest Transfer Match

slice "Review Transfer Suggestion" {
  view Transfer Suggestions from "Transfer Match Suggested"
  ui Transfer Review Screen @User
}

slice "Confirm Transfer" {
  ui Transfer Confirmation Screen @User
  command Confirm Transfer
  event Transfer Confirmed @Transfers
}

slice "Reject Transfer Suggestion" {
  ui Transfer Confirmation Screen @User
  command Reject Transfer Suggestion
  event Transfer Suggestion Rejected @Transfers
}

slice "Find Uncategorized Exceptions" {
  view Uncategorized Transactions from "Transactions Categorized"
  ui Categorization Review Screen @User
}

slice "Correct Transaction Category" {
  ui Transaction Detail Screen @User
  command Correct Transaction Category
  event Transaction Category Corrected @Categorization
}

slice "Remember Category Correction" {
  command Remember Category Correction
  event Category Rule Saved @Categorization
}
arrow Transaction Detail Screen -> Remember Category Correction

slice "Apply Category Rule" {
  view Applicable Category Rules from "Category Rule Saved"
  processor Category Rule Automation
}

slice "Reapply Category Rule" {
  command Apply Category Rule
  event Category Rule Applied @Categorization
}
arrow Category Rule Automation -> Apply Category Rule

slice "Prepare Category Targets" {
  view Target Inference Inputs from "Initial Budget Created", "Budget Categories Initialized", "Provider Records Imported", "Transactions Categorized", "Transfer Confirmed"
  processor Target Inference Automation
}

slice "Propose Category Targets" {
  command Propose Category Targets
  event Category Targets Proposed @Budget
}
arrow Target Inference Automation -> Propose Category Targets

slice "Review Category Targets" {
  view Proposed Targets from "Category Targets Proposed"
  ui Target Review Screen @User
}

slice "Approve Category Targets" {
  ui Target Approval Screen @User
  command Approve Category Targets
  event Category Targets Approved @Budget
}

slice "Adjust Category Target" {
  ui Target Review Screen @User
  command Adjust Category Target
  event Category Target Adjusted @Budget
}

slice "Review Setup Exceptions" {
  view Setup Exceptions from "Opening Balance Recorded", "Transactions Categorized", "Transfer Match Suggested", "Category Targets Proposed", "Provider Sync Failed"
  ui Setup Review Screen @User
}

slice "Calculate Budget Progress" {
  view Budget Progress Inputs from "Category Targets Approved", "Category Target Adjusted", "Transactions Categorized", "Transaction Category Corrected", "Category Rule Applied", "Transfer Confirmed", "Transfer Suggestion Rejected"
  processor Budget Progress Calculator
}

slice "Record Budget Progress" {
  command Calculate Budget Progress
  event Budget Progress Calculated @Reporting
}
arrow Budget Progress Calculator -> Calculate Budget Progress

slice "Evaluate Category Pace" {
  view Pace Evaluation Inputs from "Budget Progress Calculated"
  processor Pace Evaluation Automation
}

slice "Record Pace Status" {
  command Record Category Pace Status
  event Category Pace Status Recorded @Reporting
}
arrow Pace Evaluation Automation -> Record Category Pace Status

slice "Show Monthly Dashboard" {
  view Monthly Budget Dashboard from "Budget Progress Calculated", "Category Pace Status Recorded"
  ui Budget Dashboard Screen @User
}

slice "Show Pace Warnings" {
  view Current Pace Warnings from "Category Pace Status Recorded"
  ui Pace Warning Panel @User
}

slice "Dismiss Pace Warning" {
  ui Pace Warning Panel @User
  command Dismiss Pace Warning
  event Pace Warning Dismissed @Reporting
}

slice "Snooze Pace Warning" {
  ui Pace Warning Panel @User
  command Snooze Pace Warning
  event Pace Warning Snoozed @Reporting
}

slice "Show Pace Warning State" {
  view Pace Warning State from "Pace Warning Dismissed", "Pace Warning Snoozed"
  ui Pace Warning Panel @User
}

# Ongoing maintenance and user corrections.

slice "Schedule Recurring Sync" {
  view Due Connections from "Provider Sync Started", "Provider Records Imported"
  processor Recurring Sync Scheduler
}

slice "Start Scheduled Provider Sync" {
  command Start Scheduled Provider Sync
  event Scheduled Provider Sync Started @Connections
}
arrow Recurring Sync Scheduler -> Start Scheduled Provider Sync

slice "Retry Failed Sync" {
  view Failed Syncs from "Provider Sync Failed"
  processor Sync Retry Automation
}

slice "Retry Provider Sync" {
  command Retry Provider Sync
  event Provider Sync Retry Started @Connections
}
arrow Sync Retry Automation -> Retry Provider Sync

slice "Review Sync Status" {
  view Connection Sync Status from "Provider Sync Started", "Scheduled Provider Sync Started", "Provider Sync Retry Started", "Provider Records Imported", "Provider Sync Failed"
  ui Connection Status Screen @User
}

slice "Edit Transaction Category" {
  ui Edited Transaction Detail Screen @User
  command Edit Transaction Category
  event Transaction Category Edited @Categorization
}

slice "Recalculate After Category Edit" {
  view Changed Budget Inputs from "Transaction Category Edited"
  processor Budget Recalculation Automation
}

slice "Record Recalculated Budget Progress" {
  command Recalculate Budget Progress After Edit
  event Budget Progress Recalculated After Edit @Reporting
}
arrow Budget Recalculation Automation -> Recalculate Budget Progress After Edit

slice "Show Recalculated Budget Progress" {
  view Updated Budget Progress from "Budget Progress Recalculated After Edit"
  ui Budget Dashboard Screen @User
}

slice "Request Manual Sync" {
  ui Connection Status Screen @User
  command Request Manual Sync
  event Manual Sync Requested @Connections
}

slice "Show Manual Sync Status" {
  view Connection Sync Status again from "Manual Sync Requested"
  ui Connection Status Screen @User
}

slice "Pause Budget Automation" {
  ui Automation Settings Screen @User
  command Pause Budget Automation
  event Budget Automation Paused @Budget
}

slice "Resume Budget Automation" {
  ui Automation Settings Screen @User
  command Resume Budget Automation
  event Budget Automation Resumed @Budget
}

slice "Show Automation State" {
  view Current Automation State from "Budget Automation Paused", "Budget Automation Resumed"
  ui Automation Settings Screen @User
}

slice "Read Budget Through MCP" {
  view MCP Budget Data from "Budget Progress Calculated", "Category Pace Status Recorded"
  ui MCP Budget Query @Agent
}

slice "Read Transactions Through MCP" {
  view MCP Transaction Data from "Provider Records Imported", "Transactions Categorized", "Transaction Category Corrected", "Transaction Category Edited"
  ui MCP Transaction Query @Agent
}

slice "Change Category Through MCP" {
  translation MCP Category Change Adapter
}

slice "Apply MCP Category Change" {
  command Apply MCP Category Change
  event MCP Category Change Applied @MCP
}
arrow MCP Category Change Adapter -> Apply MCP Category Change

slice "Read Applied MCP Change" {
  view Applied MCP Changes from "MCP Category Change Applied"
  ui MCP Change Result @Agent
}

# Household access and read-only collaboration.

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

slice "View Household Dashboard" {
  view Shared Budget Dashboard from "Budget Progress Calculated", "Category Pace Status Recorded", "Household Viewer Added"
  ui Family Progress Screen @HouseholdViewer
}

slice "View Shared Transactions" {
  view Shared Transaction List from "Provider Records Imported", "Transactions Categorized", "Household Viewer Added"
  ui Family Transactions Screen @HouseholdViewer
}
