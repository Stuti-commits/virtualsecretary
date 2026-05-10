const admin = require("firebase-admin");
const {onDocumentCreated, onDocumentUpdated} =
  require("firebase-functions/v2/firestore");
const {logger} = require("firebase-functions");

admin.initializeApp();

async function sendToTopic(topic, notification, data = {}) {
  try {
    await admin.messaging().send({
      topic,
      notification,
      data,
    });
  } catch (error) {
    logger.error(`Failed to send topic notification to ${topic}`, error);
  }
}

exports.onParcelRegistered = onDocumentCreated(
  "parcel_requests/{parcelId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    await sendToTopic(
      "role_security",
      {
        title: "New parcel expected",
        body: `${data.residentName} from flat ${data.flatNumber} registered a ${data.parcelType} delivery.`,
      },
      {
        type: "parcel_expected",
        residentUid: data.residentUid || "",
      },
    );
  },
);

exports.onParcelArrivalUpdated = onDocumentUpdated(
  "parcel_requests/{parcelId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    if (before.status === after.status || after.status !== "arrived") return;

    await sendToTopic(
      `user_${after.residentUid}`,
      {
        title: "Parcel has arrived",
        body: `${after.parcelType} delivery is waiting at ${after.allowDoorDelivery ? "your door" : "the gate"}.`,
      },
      {
        type: "parcel_arrived",
        parcelId: event.params.parcelId,
      },
    );
  },
);

exports.onVisitorApproved = onDocumentCreated(
  "visitor_approvals/{visitorId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    await sendToTopic(
      "role_security",
      {
        title: "Visitor pre-approved",
        body: `${data.guestName} is approved for flat ${data.flatNumber} at ${new Date(data.expectedTime.toDate()).toLocaleString("en-IN")}.`,
      },
      {
        type: "visitor_approved",
        residentUid: data.residentUid || "",
      },
    );
  },
);

exports.onVisitorEntryExit = onDocumentUpdated(
  "visitor_approvals/{visitorId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    if (before.status === after.status) return;

    if (after.status === "entered" || after.status === "exited") {
      await sendToTopic(
        `user_${after.residentUid}`,
        {
          title: `Visitor ${after.status}`,
          body: `${after.guestName} has ${after.status} the property.`,
        },
        {
          type: "visitor_status",
          status: after.status,
        },
      );
    }
  },
);

exports.onMaintenanceFiled = onDocumentCreated(
  "maintenance_issues/{issueId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    await sendToTopic(
      "role_secretary",
      {
        title: "New maintenance issue",
        body: `${data.residentName} reported a ${data.category} issue from flat ${data.flatNumber}.`,
      },
      {
        type: "maintenance_open",
        issueId: event.params.issueId,
      },
    );
  },
);

exports.onMaintenanceStatusChanged = onDocumentUpdated(
  "maintenance_issues/{issueId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    if (before.status === after.status) return;

    await sendToTopic(
      `user_${after.residentUid}`,
      {
        title: "Maintenance status updated",
        body: `${after.category} issue is now ${after.status.replace("_", " ")}.`,
      },
      {
        type: "maintenance_status",
        status: after.status,
        issueId: event.params.issueId,
      },
    );
  },
);
