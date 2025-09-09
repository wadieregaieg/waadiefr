from django.core.management.base import BaseCommand, CommandError
from django.core.files import File
from apps.apk_updates.models import APKVersion
import os
import hashlib

class Command(BaseCommand):
    help = 'Upload APK file and create version record'

    def add_arguments(self, parser):
        parser.add_argument('version', type=str, help='Version number (e.g., 1.0.0)')
        parser.add_argument('apk_path', type=str, help='Path to APK file')
        parser.add_argument(
            '--release-notes',
            type=str,
            default='',
            help='Release notes for this version'
        )
        parser.add_argument(
            '--set-latest',
            action='store_true',
            help='Mark this version as the latest'
        )
        parser.add_argument(
            '--force-update',
            action='store_true',
            help='Mark this as a forced update'
        )

    def handle(self, *args, **options):
        version = options['version']
        apk_path = options['apk_path']
        
        # Check if file exists
        if not os.path.exists(apk_path):
            raise CommandError(f'APK file not found: {apk_path}')
        
        # Check if version already exists
        if APKVersion.objects.filter(version=version).exists():
            raise CommandError(f'Version {version} already exists')
        
        # Calculate checksum
        self.stdout.write('Calculating checksum...')
        sha256_hash = hashlib.sha256()
        with open(apk_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        checksum = sha256_hash.hexdigest()
        
        # Create version record
        self.stdout.write(f'Creating version record for {version}...')
        
        with open(apk_path, 'rb') as f:
            apk_version = APKVersion.objects.create(
                version=version,
                release_notes=options['release_notes'],
                is_latest=options['set_latest'],
                force_update=options['force_update'],
                checksum=checksum
            )
            apk_version.apk_file.save(
                f'freshk-v{version}.apk',
                File(f),
                save=True
            )
        
        self.stdout.write(
            self.style.SUCCESS(
                f'Successfully uploaded APK version {version}\n'
                f'File size: {apk_version.formatted_size}\n'
                f'Checksum: {checksum[:16]}...\n'
                f'Latest: {apk_version.is_latest}'
            )
        )
