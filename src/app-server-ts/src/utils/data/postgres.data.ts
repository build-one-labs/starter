export type ImportTypes = 'ImportAllData';
export type ExportTypes = 'ExportAllData';

const APP_DATA_FOLDER = process.env.APP_DATA_FOLDER;

export async function importData(type: ImportTypes, clearData = false) {
  console.info(`Running import of type ${type} to ${APP_DATA_FOLDER}... [clear data: ${clearData}]`);
}

export async function exportData(type: ExportTypes = 'ExportAllData') {
  console.info(`Running export of type ${type} to ${APP_DATA_FOLDER}...`);
}
