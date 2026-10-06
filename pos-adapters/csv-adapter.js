/**
 * CSV Adapter
 * Works with any POS - restaurant exports CSV and uploads it
 * Supports: staff list, shifts, sales data
 */
class CSVAdapter extends POSAdapter {
  constructor() {
    super();
    this.name = 'CSV Import';
    this.type = 'csv';
    this.data = { staff: [], shifts: [], sales: [] };
  }

  async connect() {
    // CSV is already "connected" once data is loaded
    return true;
  }

  async isConnected() {
    return this.data.staff.length > 0;
  }

  async disconnect() {
    this.data = { staff: [], shifts: [], sales: [] };
    POSAdapter.clearConfig();
  }

  /**
   * Parse CSV staff file
   * Expected columns: name, role, phone, wage, hireDate, notes
   */
  parseStaffCSV(csvText) {
    const lines = csvText.trim().split('\n');
    const headers = lines[0].split(',').map(h => h.trim().toLowerCase());
    const staff = [];

    for (let i = 1; i < lines.length; i++) {
      if (!lines[i].trim()) continue;

      const values = lines[i].split(',').map(v => v.trim());
      const row = {};
      headers.forEach((h, idx) => {
        row[h] = values[idx] || '';
      });

      if (row.name) {
        staff.push({
          id: uid(),
          name: row.name,
          role: row.role || 'Staff',
          phone: row.phone || '',
          wage: parseFloat(row.wage) || 0,
          hireDate: row.hiredate || todayISO(),
          notes: row.notes || '',
        });
      }
    }

    this.data.staff = staff;
    this.saveConfig();
    return staff;
  }

  /**
   * Handle file upload for staff
   */
  async uploadStaffFile(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = (e) => {
        try {
          const staff = this.parseStaffCSV(e.target.result);
          resolve(staff);
        } catch (err) {
          reject(err);
        }
      };
      reader.onerror = () => reject(new Error('File read failed'));
      reader.readAsText(file);
    });
  }

  async getStaff() {
    return this.data.staff;
  }

  async getShifts() {
    return this.data.shifts || [];
  }

  async getSales(fromDate, toDate) {
    return this.data.sales || [];
  }

  /**
   * Manual data entry for small restaurants
   */
  addStaffMember(name, role, phone, wage, hireDate, notes) {
    const staff = {
      id: uid(),
      name,
      role: role || 'Staff',
      phone: phone || '',
      wage: parseFloat(wage) || 0,
      hireDate: hireDate || todayISO(),
      notes: notes || '',
    };
    this.data.staff.push(staff);
    this.saveConfig();
    return staff;
  }
}

// Export for use in main app
if (typeof module !== 'undefined' && module.exports) {
  module.exports = CSVAdapter;
}
