import React from 'react';

const AlertsPage = () => {
  return (
    <div style={{ width: '100vw', height: '100vh', margin: 0, padding: 0 }}>
      <iframe
        src="https://pytorchci.grafana.net/public-dashboards/500bf186083048f39940617a80b57fd1"
        style={{ width: '100%', height: '100%', border: 'none' }}
        title="Alerts Dashboard"
      />
    </div>
  );
};

export default AlertsPage;
