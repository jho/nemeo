import "@typespec/http";
import "@typespec/rest";
import "../../docs/event-model/models/iam/contracts/iam.tsp";

using TypeSpec.Http;
using TypeSpec.Rest;
using IAM;

namespace Nemeo.IAM;

model RedirectResponse {
  @statusCode
  statusCode: 302;

  @header("Location")
  location: string;
}

model GoogleAuthCallbackQuery {
  @query
  code: string;

  @query
  state: string;

  @query
  error?: string;
}

model CreateInitialHouseholdRequest {
  name: string;
}

model HouseholdCollectionResponse {
  data: CurrentHousehold[];
  hasMore: boolean;
  nextCursor?: string;
}

/**
 * EM mapping:
 * - Model: iam
 * - Boundary: Google OIDC callback
 * - Translation: Google OIDC Callback — New Identity
 * - Command: IAM.Commands.signUp
 * - Result: IAM.UserAccountCreated
 */
@route("/v1/auth/google/start")
@get
op startGoogleAuthentication(): RedirectResponse;

/**
 * EM mapping:
 * - Model: iam
 * - Boundary: Google OIDC callback
 * - Translations: Google OIDC Callback — New Identity or Google OIDC Callback — Existing Identity
 * - Commands: IAM.Commands.signUp or IAM.Commands.authenticate
 * - Results: IAM.UserAccountCreated or IAM.UserAuthenticated
 */
@route("/v1/auth/google/callback")
@get
op completeGoogleAuthentication(...GoogleAuthCallbackQuery): RedirectResponse;

/**
 * EM mapping:
 * - Model: iam
 * - Slice: view-current-user
 * - View: IAM.Views.getCurrentUser / IAM.CurrentUser
 * - Auth: authenticated principal
 */
@route("/v1/users/me")
@get
op getCurrentUser(): CurrentUser;

/**
 * EM mapping:
 * - Model: iam
 * - Slice: view-current-household
 * - View: IAM.Views.getCurrentHousehold / IAM.CurrentHousehold
 * - Auth: authenticated principal
 */
@route("/v1/households")
@get
op listHouseholds(): HouseholdCollectionResponse;

/**
 * EM mapping:
 * - Model: iam
 * - Slice: create-initial-household
 * - Command: IAM.Commands.createInitialHousehold
 * - Input projection: userId comes from the authenticated session; name comes from the request
 * - Result: IAM.HouseholdCreated and IAM.CurrentHousehold
 */
@route("/v1/households")
@post
op createInitialHousehold(@body body: CreateInitialHouseholdRequest): CurrentHousehold;
