begin
  require 'right_aws'
rescue LoadError
  $stderr.puts "This gem requires the right_aws gem. Please verify it is installed"
  exit 1
end

class RightWrapper
  SNAP_WAIT_TIME = 5
  AVAILABLE_DEVICES = ("j".."p").map {|x| "/dev/sd#{x}"}.freeze
  
  attr_accessor :ec2
  
  def initialize(aws_access_key_id, aws_secret_access_key)
    @ec2 = RightAws::Ec2.new(aws_access_key_id, aws_secret_access_key)
  end
  
  def find_instance(target_instance_id)
    instances = @ec2.describe_instances([target_instance_id])
    unless target_instance = instances.first
      $stderr.puts "Target instance #{target_instance_id} is not up. Cannot complete operation."
      exit 1
    end
    target_instance
  end
  
  def find_instance_by_eip(eip)
    unless address = @ec2.describe_addresses.detect {|x| x[:public_ip] == eip}
      puts "No address information found for #{eip}"
    end
    
    if instance_id = address[:instance_id]
      find_instance(instance_id)
    else
      puts "No instance currently associated with #{eip}"
    end
  end
  
  def find_volume(target_volume_id)
    volumes = @ec2.describe_volumes([target_volume_id])
    unless target_volume = volumes.first
      $stderr.puts "Target volume #{target_volume_id} is not up. Cannot complete operation."
      exit 1
    end
    target_volume
  end
  
  def find_volumes_by(options)
    @ec2.describe_volumes.select do |volume|
      options.to_a.all? { |k, v| volume[k] == v}
    end
  end
  
  def find_snapshots_by(options)
    @ec2.describe_snapshots.select do |snap|
      options.to_a.all? { |k, v| snap[k] == v}
    end
  end
  
  def find_attached_volumes(target_instance)
    target_instance_id = target_instance[:aws_instance_id] or raise "Can't find instance id of nil"

    all_volumes = @ec2.describe_volumes
    current_volumes = all_volumes.select {|vol| vol[:aws_instance_id] == target_instance_id && vol[:aws_attachment_status] == "attached"}
    if current_volumes.size > 0
      puts "Found the following volumes attached to #{target_instance_id}:"
      current_volumes.each do |vol|
        puts "-- #{vol[:aws_id]} attached to #{vol[:aws_device]} on #{vol[:aws_attached_at]}"
      end
    else
      puts "No volumes currently attached to #{target_instance_id}."
    end

    current_volumes
  end

  def create_snapshot(target_volume, tags={})
    tag_string = ''
    target_volume_id = target_volume[:aws_id]

    puts "Creating snapshot of #{target_volume_id}"
    unless tags.empty?
      tag_string = tags.map {|k,v| [k.to_s, v.to_s].join(":")}.join(" ")
      puts "-- Tagging snapshot with #{tag_string}"
    end

    snap_id = @ec2.create_snapshot(target_volume_id, tag_string)[:aws_id]

    while true
      snap_data = @ec2.describe_snapshots.detect {|snap| snap[:aws_id] == snap_id}    

      puts "-- Progress of snapshot #{snap_id} is #{snap_data[:aws_progress]}."
      break if snap_data[:aws_status] == "completed"

      sleep SNAP_WAIT_TIME
    end

    snap_id
  end

  def share_snapshot(snap_id, *users)
    puts "Sharing snapshot #{snap_id} with #{users.join(', ')}"
    @ec2.modify_snapshot_attribute_create_volume_permission_add_users(snap_id, *users)
  end

  def get_tags_for_snapshot(snap)
    snap[:aws_description].squeeze(" ").split(" ").inject({}) { |c, t| key, value = t.split(":"); c[key.to_sym] = value; c}
  end
  
  def delete_snapshot(snap_id)
    puts "Deleting snapshot #{snap_id}"
    @ec2.delete_snapshot(snap_id)
  end

  def create_volume(snap_id, volume_size, zone)
    puts "Creating volume for snapshot #{snap_id}"
    puts "-- Source volume is #{volume_size}GB"
    puts "-- Target instance is in the '#{zone}' zone"
    
    vol_id = @ec2.create_volume(snap_id, volume_size, zone)[:aws_id]
    wait_for_volume(vol_id, "available")
    vol_id
  end
  
  def attach_volume(volume_id, target_instance, device)
    puts "Attaching volume #{volume_id} to instance #{target_instance[:aws_instance_id]} on #{device}"
    @ec2.attach_volume(volume_id, target_instance[:aws_instance_id], device)
    wait_for_volume(volume_id, "attached")
  end
  
  def detach_volume(volume)
    puts "Detatching volume #{volume[:aws_id]} from #{volume[:device]} on instance #{volume[:aws_instance_id]}"
    @ec2.detach_volume(volume[:aws_id], volume[:aws_instance_id], volume[:device])
    wait_for_volume(volume[:aws_id], "available")
  end
  
  def delete_volume(volume)
    puts "Deleting the volume #{volume[:aws_id]}"
    @ec2.delete_volume(volume[:aws_id])
  end
  
  def wait_for_volume(vol_id, status)
    while true
      vol_data = @ec2.describe_volumes.detect {|vol| vol[:aws_id] == vol_id}
      puts "-- Attachment status of volume #{vol_id} is #{vol_data[:aws_attachment_status]}." unless vol_data[:aws_attachment_status].nil?
      puts "-- AWS Status of volume #{vol_id} is #{vol_data[:aws_status]}"
      puts "-- Progress of volume #{vol_id} is #{vol_data[:aws_progress]}." unless vol_data[:aws_progress].nil?
      break if vol_data[:aws_status] == status || vol_data[:aws_attachment_status] == status

      sleep SNAP_WAIT_TIME
    end
  end
  
  class << self
    def freeze_xfs(device, &block)
      system("xfs_freeze -f #{device}")
      yield
      system("xfs_freeze -u #{device}")      
    end
  end
end
