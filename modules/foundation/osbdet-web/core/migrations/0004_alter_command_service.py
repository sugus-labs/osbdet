# Generated by Django 3.2.2 on 2023-06-17 21:46

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0003_auto_20230617_2118'),
    ]

    operations = [
        migrations.AlterField(
            model_name='command',
            name='service',
            field=models.CharField(choices=[('jupyter', 'jupyter'), ('nifi', 'nifi'), ('hadoop', 'hadoop'), ('spark', 'spark'), ('kafka', 'kafka'), ('mariadb', 'mariadb'), ('superset', 'superset'), ('mongodb', 'mongodb'), ('minio', 'minio'), ('airflow', 'airflow'), ('truckfleet-sim', 'truckfleet-sim')], default='jupyter', max_length=20),
        ),
    ]
