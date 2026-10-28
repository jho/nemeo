model "Budgeting"

persona User
persona HouseholdViewer
persona Agent

context Budget
context Category

slice "Create Initial Budget" {
  translation Account Selection Completed consumes ledger:event.budget-accounts-selected
  command Create Initial Budget
  event Budget Created @Budget
}

slice "Prepare Category Initialization" {
  view Category Initialization Inputs from "Budget Created"
  processor Category Taxonomy Initializer
}

slice "Create Category" {
  command Create Category
  event Category Created @Category
}
arrow Category Taxonomy Initializer -> Create Category

slice "Prepare Budget Category Membership" {
  view Categories To Add from "Category Created"
  processor Budget Category Initializer
}

slice "Add Category To Budget" {
  command Add Category To Budget
  event Category Added To Budget @Budget
}
arrow Budget Category Initializer -> Add Category To Budget

slice "Prepare Category Targets" {
  view Target Inference Inputs from "Budget Created", "Category Added To Budget"
  processor Target Inference Automation
}

slice "Propose Category Target" {
  command Propose Category Target
  event Category Target Proposed @Category
}
arrow Target Inference Automation -> Propose Category Target

slice "Approve Category Target" {
  ui Target Approval Screen @User
  command Approve Category Target
  event Category Target Approved @Category
}

slice "Adjust Category Target" {
  ui Target Review Screen @User
  command Adjust Category Target
  event Category Target Adjusted @Category
}

slice "Show Category Targets" {
  view Proposed Targets from "Category Target Proposed", "Category Target Approved", "Category Target Adjusted"
  ui Target Review Screen @User
}

slice "Refresh Budget Activity" {
  translation Ledger Activity Changed consumes ledger:event.provider-records-imported, ledger:event.transactions-categorized, ledger:event.transfer-confirmed, ledger:event.transaction-category-corrected, ledger:event.category-rule-applied, ledger:event.transaction-category-edited
  command Calculate Budget Progress
  event Budget Progress Calculated @Budget
}

slice "Review Setup Exceptions" {
  view Setup Exceptions from "Budget Progress Calculated"
  ui Setup Review Screen @User
}

slice "Recalculate After Category Edit" {
  translation Category Edit Applied consumes ledger:event.transaction-category-edited
  command Recalculate Budget Progress After Edit
  event Budget Progress Recalculated After Edit @Budget
}

slice "Show Recalculated Budget Progress" {
  view Updated Budget Progress from "Budget Progress Recalculated After Edit"
  ui Budget Dashboard Screen @User
}

slice "Prepare Pace Evaluation" {
  view Pace Evaluation Inputs from "Budget Progress Calculated"
  processor Pace Evaluation Automation
}

slice "Evaluate Category Pace" {
  command Record Category Pace Status
  event Category Pace Status Recorded @Category
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
  event Pace Warning Dismissed @Category
}

slice "Snooze Pace Warning" {
  ui Pace Warning Panel @User
  command Snooze Pace Warning
  event Pace Warning Snoozed @Category
}

slice "Show Pace Warning State" {
  view Pace Warning State from "Pace Warning Dismissed", "Pace Warning Snoozed"
  ui Pace Warning Panel @User
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

slice "View Household Dashboard" {
  view Shared Budget Dashboard from "Budget Progress Calculated", "Category Pace Status Recorded"
  ui Family Progress Screen @HouseholdViewer
}
