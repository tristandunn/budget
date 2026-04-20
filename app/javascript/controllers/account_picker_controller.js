import PickerController from "controllers/picker_controller";

/*
 * Manages the account picker. Groups accounts under cash or credit based on
 * each item's credit flag so the list mirrors the split the accounts index
 * already renders.
 */
export default class extends PickerController {
  // Return the group label based on the account type.
  groupFor(item) {
    return item.credit
      ? "Credit"
      : "Cash";
  }
}
