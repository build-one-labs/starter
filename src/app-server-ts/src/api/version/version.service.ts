import { Injectable } from '@nestjs/common';
import { readFileSync } from 'fs';
import { join } from 'path';
import { PostgresVersionChecker } from './providers/postgres.version';

@Injectable()
export class VersionService {
  constructor(protected readonly postgresVersionChecker: PostgresVersionChecker) {}

  async getInfo() {
    const pkg = JSON.parse(readFileSync(join(process.cwd(), 'package.json'), 'utf8'));
    return {
      name: pkg.name,
      version: process.env.BUILD_VERSION ?? pkg.version,
      buildTime: process.env.BUILD_TIME ?? new Date(),
      dependencies: {
        node: process.version,
        nest: require('@nestjs/common/package.json').version,
        postgres: await this.postgresVersionChecker.getVersion()
      }
    };
  }
}
