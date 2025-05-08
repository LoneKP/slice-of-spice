// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "./application";
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading";

eagerLoadControllersFrom("controllers", application);

// Register the sortable controller
import SortableController from "./sortable_controller";
application.register("sortable", SortableController);
