/**
 * Cluster POS Adapter
 * Direct integration with Cluster (Montreal-based POS)
 * Supports: OAuth login, staff sync, shifts, sales data
 */
class ClusterAdapter extends POSAdapter {
  constructor() {
    super();
    this.name = 'Cluster POS';
    this.type = 'cluster';
    this.apiBase = 'https://api.clusterpos.com'; // Update with real Cluster API endpoint
    this.apiKey = null;
    this.restaurantId = null;
  }

  /**
   * Connect to Cluster using API key
   * TODO: Implement OAuth flow when Cluster API is available
   */
  async connect(apiKey, restaurantId) {
    if (!apiKey || !restaurantId) {
      throw new Error('API key and restaurant ID required');
    }

    this.apiKey = apiKey;
    this.restaurantId = restaurantId;

    // Test connection
    try {
      const response = await this.callAPI('/test');
      if (response.ok) {
        this.config = { apiKey, restaurantId };
        this.saveConfig();
        return true;
      }
    } catch (err) {
      throw new Error('Failed to connect to Cluster: ' + err.message);
    }
  }

  /**
   * Check if connected and valid
   */
  async isConnected() {
    if (!this.apiKey) return false;

    try {
      const response = await this.callAPI('/test');
      return response.ok;
    } catch {
      return false;
    }
  }

  async disconnect() {
    this.apiKey = null;
    this.restaurantId = null;
    this.config = {};
    POSAdapter.clearConfig();
  }

  /**
   * Call Cluster API
   */
  async callAPI(endpoint, method = 'GET', data = null) {
    const options = {
      method,
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json',
      },
    };

    if (data) {
      options.body = JSON.stringify(data);
    }

    const response = await fetch(`${this.apiBase}${endpoint}`, options);

    if (!response.ok) {
      throw new Error(`Cluster API error: ${response.status}`);
    }

    return response.json();
  }

  /**
   * Get staff from Cluster
   * TODO: Update endpoint based on actual Cluster API
   */
  async getStaff() {
    try {
      const data = await this.callAPI(
        `/restaurants/${this.restaurantId}/employees`
      );
      return this.transformStaff(data.employees || []);
    } catch (err) {
      console.error('Error fetching staff from Cluster:', err);
      return [];
    }
  }

  /**
   * Get shifts from Cluster
   * TODO: Update endpoint based on actual Cluster API
   */
  async getShifts() {
    try {
      const data = await this.callAPI(
        `/restaurants/${this.restaurantId}/shifts`
      );
      return this.transformShifts(data.shifts || []);
    } catch (err) {
      console.error('Error fetching shifts from Cluster:', err);
      return [];
    }
  }

  /**
   * Get sales from Cluster
   * TODO: Update endpoint based on actual Cluster API
   */
  async getSales(fromDate, toDate) {
    try {
      const data = await this.callAPI(
        `/restaurants/${this.restaurantId}/sales?from=${fromDate}&to=${toDate}`
      );
      return this.transformSales(data.sales || []);
    } catch (err) {
      console.error('Error fetching sales from Cluster:', err);
      return [];
    }
  }

  /**
   * Transform Cluster staff format to standard format
   */
  transformStaff(clusterStaff) {
    return clusterStaff.map(e => ({
      id: e.id || uid(),
      name: e.name || e.firstName + ' ' + e.lastName,
      role: e.position || e.role || 'Staff',
      phone: e.phone || e.phoneNumber || '',
      wage: parseFloat(e.hourlyRate || e.wage) || 0,
      hireDate: e.hireDate || e.startDate || todayISO(),
      notes: e.notes || e.specialNotes || '',
    }));
  }

  /**
   * Transform Cluster shifts to standard format
   */
  transformShifts(clusterShifts) {
    return clusterShifts.map(s => ({
      id: s.id || uid(),
      staffId: s.employeeId || s.staffId,
      date: s.date || s.shiftDate,
      start: s.startTime || s.start,
      end: s.endTime || s.end,
    }));
  }

  /**
   * Transform Cluster sales to standard format
   */
  transformSales(clusterSales) {
    return clusterSales.map(s => ({
      id: s.id || uid(),
      date: s.date || s.saleDate,
      dinein: parseFloat(s.dineIn || s.dinein || 0),
      takeout: parseFloat(s.takeOut || s.takeout || 0),
      delivery: parseFloat(s.delivery || 0),
      catering: parseFloat(s.catering || 0),
    }));
  }

  /**
   * OAuth login flow (placeholder)
   * TODO: Implement actual OAuth with Cluster
   */
  static async initiateOAuth() {
    const clientId = 'YOUR_CLUSTER_CLIENT_ID'; // Store in .env
    const redirectUri = `${window.location.origin}/pos-callback`;
    const authUrl = `https://auth.clusterpos.com/oauth/authorize?client_id=${clientId}&redirect_uri=${redirectUri}`;

    window.location.href = authUrl;
  }

  /**
   * Handle OAuth callback
   * TODO: Implement token exchange
   */
  static async handleOAuthCallback(code) {
    // Exchange authorization code for access token
    // Store token securely
    // Return ClusterAdapter instance
  }
}

// Export for use in main app
if (typeof module !== 'undefined' && module.exports) {
  module.exports = ClusterAdapter;
}
