/**
 * Koeboard: the @handy-computer/models catalog plus the models Koeboard
 * publishes itself (src-tauri/src/catalog/koeboard_catalog.json, the same
 * file the backend merges). Import `catalog` from here, not from the package,
 * so those models are offered, graded and recommended like the rest.
 */
import {
  catalog as upstream,
  createCatalog,
  type CatalogData,
  type CatalogModel,
} from "@handy-computer/models";
import extra from "../../../src-tauri/src/catalog/koeboard_catalog.json";

const known = new Set(upstream.data.models.map((m) => m.id));
const extraModels = (extra.models as unknown as CatalogModel[]).filter(
  (m) => !known.has(m.id),
);
const extraResults = Object.fromEntries(
  Object.entries(extra.results).filter(([id]) => !known.has(id)),
) as unknown as CatalogData["results"];

export const catalog = createCatalog({
  ...upstream.data,
  models: [...upstream.data.models, ...extraModels],
  results: { ...upstream.data.results, ...extraResults },
});
