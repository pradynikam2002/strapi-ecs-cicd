Task 14 - Using Unleash for Feature Flagging in a React App

What is Unleash?

[Unleash](https://www.getunleash.io/) is an *open-source feature flag management tool*. It allows you to:
- Turn features *on or off* without deploying code.
- Test new features safely with a small group before a full release.
- Roll back features immediately if something breaks.
- Enable **A/B testing**, **canary releases*, *user-specific features*, etc.

It gives developers more control over feature rollout.

---

WHy use Unleash?

- *Safe deployments*: Push code to production without enabling all features at once.
- *Controlled rollout*: Gradually release features to specific users/groups.
- *Dynamic toggling*: Turn on/off features without restarting the app.

---

 Setting Up Unleash Locally for a React App

This example demonstrates how to:
1. Run the *Unleash server locally using Docker*
2. Connect a *React app to Unleash* using the Unleash Frontend SDK.
3. Toggle feaures dynamically from the Unleash UI.

---
