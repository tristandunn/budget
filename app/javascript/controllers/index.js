import { application } from "controllers/application";
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading";
import PickerController from "controllers/picker_controller";

eagerLoadControllersFrom("controllers", application);

application.register("account-picker", PickerController);
application.register("category-picker", PickerController);
