model "Ledger"

persona User
persona HouseholdViewer
persona Agent

context Account
context Transaction
context Rule

slice "Receive Provider Records" {
  translation Provider Record Intake consumes feeds:event.provider-data-normalized
  command Receive Provider Records
  event Provider Records Received @Account
}

slice "Prepare Provider Record Import" {
  view Records To Import from "Provider Records Received"
  processor Provider Record Importer
}

slice "Import Provider Account" {
  command Import Provider Account
  event Account Imported @Account
}
arrow Provider Record Importer -> Import Provider Account

slice "Import Provider Transaction" {
  command Import Provider Transaction
  event Transaction Imported @Transaction public
}
arrow Provider Record Importer -> Import Provider Transaction

slice "Select Accounts for Budget" {
  ui Account Selection Screen @User
  command Select Budget Accounts
  event Budget Accounts Selected @Account public
}

slice "Show Selected Budget Accounts" {
  view Selected Budget Accounts from "Budget Accounts Selected"
  ui Account Selection Screen @User
}

slice "Reconcile Account Balances" {
  view Balance Reconciliation Worklist from "Account Imported"
  processor Balance Reconciler
}
arrow Balance Reconciler -> Record Opening Balance

slice "Record Opening Balance" {
  ui Account Reconciliation Screen @User
  command Record Opening Balance
  event Opening Balance Recorded @Account
}

slice "Review Imported Transactions" {
  view Imported Transactions from "Transaction Imported", "Opening Balance Recorded"
  ui Transactions Screen @User
}

slice "Find Transactions to Categorize" {
  view Transactions Needing Categories from "Transaction Imported"
  ui Categorization Review Screen @User
  processor Categorization Automation
}

slice "Categorize Transactions Automatically" {
  command Categorize Transactions
  event Transactions Categorized @Transaction public
}
arrow Categorization Automation -> Categorize Transactions

slice "Find Uncategorized Exceptions" {
  view Uncategorized Transactions from "Transactions Categorized"
  ui Categorization Review Screen @User
}

slice "Find Transfer Candidates" {
  view Transfer Candidates from "Transactions Categorized"
  ui Transfer Review Screen @User
  processor Transfer Matching Automation
}

slice "Suggest Transfer Match" {
  command Suggest Transfer Match
  event Transfer Match Suggested @Transaction
}
arrow Transfer Matching Automation -> Suggest Transfer Match

slice "Review Transfer Suggestion" {
  view Transfer Suggestions from "Transfer Match Suggested"
  ui Transfer Review Screen @User
}

slice "Confirm Transfer" {
  ui Transfer Confirmation Screen @User
  command Confirm Transfer
  event Transfer Confirmed @Transaction public
}

slice "Reject Transfer Suggestion" {
  ui Transfer Confirmation Screen @User
  command Reject Transfer Suggestion
  event Transfer Suggestion Rejected @Transaction
}

slice "Show Transfer Suggestion State" {
  view Transfer Suggestions again from "Transfer Suggestion Rejected"
  ui Transfer Review Screen @User
}

slice "Correct Transaction Category" {
  ui Transaction Detail Screen @User
  command Correct Transaction Category
  event Transaction Category Corrected @Transaction public
}

slice "Remember Category Correction" {
  ui Transaction Detail Screen @User
  command Remember Category Correction
  event Category Rule Saved @Rule
}

slice "Find Applicable Category Rules" {
  view Applicable Category Rules from "Category Rule Saved"
  ui Categorization Review Screen @User
  processor Category Rule Automation
}

slice "Apply Category Rule" {
  command Apply Category Rule
  event Category Rule Applied @Transaction public
}
arrow Category Rule Automation -> Apply Category Rule

slice "Edit Transaction Category" {
  ui Transaction Detail Screen @User
  command Edit Transaction Category
  event Transaction Category Edited @Transaction public
}

slice "Read Transactions Through MCP" {
  view MCP Transaction Data from "Transaction Imported", "Transactions Categorized", "Transaction Category Corrected", "Transaction Category Edited"
  ui MCP Transaction Query @Agent
}

slice "Change Category Through MCP" {
  translation MCP Category Change Adapter from "MCP Transaction Data"
  command Apply MCP Category Change
  event MCP Category Change Applied @Transaction
}

slice "Show Applied MCP Change" {
  view Applied MCP Changes from "MCP Category Change Applied"
  ui MCP Change Result @Agent
}

slice "View Shared Transactions" {
  view Shared Transaction List from "Transaction Imported", "Transactions Categorized"
  ui Family Transactions Screen @HouseholdViewer
}
