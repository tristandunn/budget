import PickerController from "controllers/picker_controller";

/*
 * Manages the category picker. Groups subcategories under their parent
 * category name so the list mirrors the hierarchy the form previously
 * rendered as an optgroup select.
 */
export default class extends PickerController {
  // Return the parent category name used to group subcategories.
  groupFor(item) {
    return item.parent_name;
  }
}
