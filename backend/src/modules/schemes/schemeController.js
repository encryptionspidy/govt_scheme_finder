import { schemeService } from "./schemeService.js";

export const schemeController = {
  async list(req, res) {
    const result = await schemeService.listSchemes(req.query);
    res.json({
      data: result.items,
      pagination: {
        page: result.page,
        limit: result.limit,
        total: result.total,
        hasMore: result.hasMore
      }
    });
  },

  async search(req, res) {
    const result = await schemeService.searchSchemes(req.query);
    res.json({
      data: result.items,
      pagination: {
        page: result.page,
        limit: result.limit,
        total: result.total,
        hasMore: result.hasMore
      }
    });
  },

  async categories(_req, res) {
    const data = await schemeService.getCategories();
    res.json({ data });
  },

  async ministries(_req, res) {
    const data = await schemeService.getMinistries();
    res.json({ data });
  },

  async beneficiaryTypes(_req, res) {
    const data = await schemeService.getBeneficiaryTypes();
    res.json({ data });
  },

  async listByCategory(req, res) {
    req.query = { ...req.query, category: req.params.category };
    return schemeController.list(req, res);
  },

  async listByState(req, res) {
    req.query = { ...req.query, state: req.params.state };
    return schemeController.list(req, res);
  },

  async getById(req, res) {
    const scheme = await schemeService.getSchemeById(req.params.id);
    res.json({ data: scheme });
  },

  async recommend(req, res) {
    const page = req.query.page || 1;
    const limit = req.query.limit || 20;
    const result = await schemeService.recommend(req.body, { page, limit });
    res.json({
      data: result.items,
      pagination: {
        page: result.page,
        limit: result.limit,
        total: result.total,
        hasMore: result.hasMore
      }
    });
  }
};
