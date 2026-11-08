import "@typespec/http";
import "@typespec/rest";
import "../../docs/event-model/models/iam/contracts/iam.tsp";

using TypeSpec.Http;
using TypeSpec.Rest;
using IAM;

// Keep the HTTP binding in the Nemeo service namespace. The imported generated
// IAM contract remains the source of truth for the domain shapes and operation
// mapping; this file owns only the public HTTP projections.
namespace Nemeo;

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

// Reuse the generated command payload while omitting the userId supplied by
// the authenticated principal.
model CreateInitialHouseholdRequest is OmitProperties<CreateInitialHousehold, "userId">;

model HouseholdCollectionResponse {
  data: CurrentHousehold[];
  hasMore: boolean;
  nextCursor?: string;
}

@route("/v1")
interface HttpCommands extends IAM.Commands {
  /**
   * EM mapping: iam / create-initial-household / Commands.createInitialHousehold.
   * The authenticated principal supplies userId; the HTTP body supplies name.
   */
  @route("/households")
  @post
  op createInitialHousehold(@body body: CreateInitialHouseholdRequest): {
    @statusCode
    _: 201;

    @header("Location")
    location: string;

    @body
    household: CurrentHousehold;
  };
}

// This is a transport projection rather than a one-to-one publication of the
// generated Views interface: its household view is exposed as a collection
// and its user view is scoped to the authenticated principal.
@route("/v1")
interface HttpViews extends IAM.Views {
  /** EM mapping: iam / view-current-user / Views.getCurrentUser. */
  @route("/users/me")
  @get
  op getCurrentUser(): CurrentUser;

  /** EM mapping: iam / view-current-household / Views.getCurrentHousehold. */
  @route("/households")
  @get
  op getCurrentHousehold(): HouseholdCollectionResponse;
}

/**
 * OAuth is an application-boundary translation rather than a one-to-one
 * transport projection of a single generated command. The callback chooses
 * signUp or authenticate from the provider subject, then redirects to the UI.
 */
@route("/v1/auth/google")
interface HttpAuthentication {
  /** Starts the Google OIDC translation. */
  @route("/start")
  @get
  op startGoogleAuthentication(): RedirectResponse;

  /** Maps to Google OIDC Callback — New Identity or Existing Identity. */
  @route("/callback")
  @get
  op completeGoogleAuthentication(...GoogleAuthCallbackQuery): RedirectResponse;
}
