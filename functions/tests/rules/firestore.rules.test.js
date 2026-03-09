const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const RULES_PATH = path.resolve(__dirname, "../../../firestore.rules");

let testEnv;
let assertFails;
let assertSucceeds;
let initializeTestEnvironment;
let doc;
let getDoc;
let setDoc;
let updateDoc;

test.before(async () => {
  ({ initializeTestEnvironment, assertFails, assertSucceeds } = await import(
    "@firebase/rules-unit-testing"
  ));
  ({ doc, getDoc, setDoc, updateDoc } = await import("firebase/firestore"));

  testEnv = await initializeTestEnvironment({
    projectId: "demo-turqapp",
    firestore: {
      rules: fs.readFileSync(RULES_PATH, "utf8"),
    },
  });
});

test.after(async () => {
  await testEnv.cleanup();
});

test.afterEach(async () => {
  await testEnv.clearFirestore();
});

test("users collection denies unauthenticated reads", async () => {
  const unauthCtx = testEnv.unauthenticatedContext();
  await assertFails(getDoc(doc(unauthCtx.firestore(), "users/some-user")));
});

test("users collection allows owner create/read for own document", async () => {
  const uid = "owner-user";
  const ownerCtx = testEnv.authenticatedContext(uid);
  const ownerDoc = doc(ownerCtx.firestore(), `users/${uid}`);

  await assertSucceeds(setDoc(ownerDoc, { firstName: "Turq" }));
  await assertSucceeds(getDoc(ownerDoc));
});

test("users collection blocks owner from writing moderation fields", async () => {
  const uid = "moderation-owner";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `users/${uid}`), {
      firstName: "Owner",
      isBanned: false,
    });
  });

  const ownerCtx = testEnv.authenticatedContext(uid);
  await assertFails(
    updateDoc(doc(ownerCtx.firestore(), `users/${uid}`), { isBanned: true }),
  );
});
