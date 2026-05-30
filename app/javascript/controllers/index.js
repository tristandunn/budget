import { application } from "controllers/application";
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading";
import PickerController from "controllers/picker_controller";

eagerLoadControllersFrom("controllers", application);

application.register("account-picker", PickerController);
application.register("frequency-picker", PickerController);
application.register("from-account-picker", PickerController);
application.register("to-account-picker", PickerController);
