module S3v2Helper

  require 'base64'
  require 'hmac-sha1'

  include PathHelper

  def s3_get_files s3_info, path

    path = path_prettify path

    begin

      s3_client = get_s3_client(s3_info)

      resp = s3_client.list_objects(bucket: s3_info[:aws_bucket_name], prefix: path)

      files = resp.contents.map { |o|
        {
            key: o.key,
            file: o.key[path.length..-1]
        }
      }
                  .select { |o|
        false == (o[:key].end_with?('/')) # this is an empty folder
      }

      return {error: nil, files: files}

    rescue Aws::S3::Errors::ServiceError => ex
      return {error: "#{ex.class}: #{ex.message}", files: []}
    end
  end


  def s3_get_tree s3_info, path

    s3_client = get_s3_client(s3_info)

    path = path_prettify path

    begin

      resp = s3_client.list_objects(bucket: s3_info[:aws_bucket_name], prefix: path, delimiter: '/')

      files = resp.contents.map { |f|
        {
            key: f[:key],
            name: f[:key][path.length..-1],
            size: f[:size],
            size_pretty: number_to_human_size(f[:size])
        }
      }.select { |f|
        f[:name] != ''
      }

      json_files = files.select { |f| f[:key].end_with?('.json') }
      regular_files = files.select { |f| !(f[:key].end_with?('.json')) }

      extra_json_files = []

      json_files.each { |json_file|
        regular_file = regular_files.find { |f|
          f[:key] + '.json' == json_file[:key]
        }
        if regular_file
          regular_file[:metadata_file] = json_file
        else
          extra_json_files << json_file
        end
      }

      folders = resp.common_prefixes.map { |f|
        {
            full_path: f[:prefix],
            name: f[:prefix][path.length..-2],
        }
      }

      return {error: nil, files: regular_files + extra_json_files, folders: folders}


    rescue Aws::S3::Errors::ServiceError => ex
      return {error: "#{ex.class}: #{ex.message}", files: [], folders: []}
    end

  end


  def s3_get_files_with_last_modified_date s3_info, path


    path = path_prettify(path)

    s3_client = get_s3_client(s3_info)

    resp = s3_client.list_objects(bucket: s3_info[:aws_bucket_name], prefix: path)

    resp.contents.map { |f|
      {
          key: f[:key],
          head: {last_modified: f[:last_modified]}
      }
    }

  end


  def s3_get_file_size s3_info, key

    s3_bucket = get_s3_bucket(s3_info)

    if s3_bucket.object(key).exists?
      return s3_bucket.object(key).content_length
    else
      return nil
    end

  end


  def s3_get_signed_upload s3_info, to_sign

    hmac = HMAC::SHA1.new(s3_info[:aws_bucket_secret_access_key])

    hmac.update(to_sign)

    Base64.encode64("#{hmac.digest}").gsub("\n", '')

  end


  def s3_delete_files s3_info, files, folders

    s3_client = get_s3_client(s3_info)

    keys_to_delete = files || []

    (folders||[]).each { |folder|

      resp = s3_client.list_objects(bucket: s3_info[:aws_bucket_name], prefix: folder)

      resp.contents.each { |f|
        keys_to_delete << f[:key]
      }
    }

    json_keys_to_delete = []

    keys_to_delete.each { |key|
      if key.ends_with?('.json') == false
        json_key = key + '.json'
        if s3_exists?(s3_info, json_key)
          # json_keys_to_delete << key + '.json'
          json_keys_to_delete << json_key
        end
      end
    }

    if Rails.configuration.aws_endpoint.nil?
      resp = s3_client.delete_objects({
                                          bucket: s3_info[:aws_bucket_name],
                                          delete: {
                                              objects: (keys_to_delete + json_keys_to_delete).map { |key|
                                                {key: key}
                                              }
                                          }
                                      })
      return resp.deleted.map { |d| d[:key] } #fake S3
    else
      (keys_to_delete + json_keys_to_delete).each do |key|
        s3_client.delete_object(
            {bucket: s3_info[:aws_bucket_name],
             key: key}
        )
      end
    end

  end


  def s3_create_folder s3_info, folder_path

    begin

      if folder_path.blank? == false
        if !folder_path.end_with?("/")
          folder_path += '/'
        end

        s3_client = get_s3_client(s3_info)

        s3_client.put_object({
                                 bucket: s3_info[:aws_bucket_name],
                                 key: folder_path,
                             })

      end

      return {}

    rescue Aws::S3::Errors::ServiceError => ex
      return {error: "#{ex.class}: #{ex.message}"}
    end

  end


  def s3_rename_file s3_info, old_key, new_key

    begin

      if old_key != new_key

        s3_client = get_s3_client(s3_info)

        resp = s3_client.copy_object({
                                         bucket: s3_info[:aws_bucket_name],
                                         copy_source: s3_info[:aws_bucket_name] + '/' + old_key,
                                         key: new_key
                                     })

        resp = s3_client.delete_object({
                                           bucket: s3_info[:aws_bucket_name],
                                           key: old_key
                                       })

        if old_key.ends_with?('.json') == false and get_s3_bucket(s3_info).object(old_key + '.json').exists?

          resp = s3_client.copy_object({
                                           bucket: s3_info[:aws_bucket_name],
                                           copy_source: s3_info[:aws_bucket_name] + '/' + old_key + '.json',
                                           key: new_key + '.json'
                                       })

          resp = s3_client.delete_object({
                                             bucket: s3_info[:aws_bucket_name],
                                             key: old_key + '.json'
                                         })

        end

      end

    rescue Aws::S3::Errors::ServiceError => ex
      return {error: "#{ex.class}: #{ex.message}"}
    end

  end


  def s3_copy_files s3_info, files, folders, destination, delete_source = false

    s3_client = get_s3_client(s3_info)

    begin

      files_to_move = (files || []).map { |file|
        {
            source_key: file,
            destination: destination + file[file.rindex(/\//)+1..-1]
        }
      }

      (folders||[]).each { |folder|

        resp = s3_client.list_objects(bucket: s3_info[:aws_bucket_name], prefix: folder)

        folder_prefix = ''

        last_slash_index = folder[0..-2].rindex(/\//)

        if last_slash_index != nil
          folder_prefix = folder[0..last_slash_index]
        end

        resp.contents.each { |f|
          files_to_move << {
              source_key: f[:key],
              destination: destination + f[:key][folder_prefix.length..-1]
          }
        }
      }

      s3_bucket = get_s3_bucket(s3_info)

      files_to_move.each { |file|

        if file[:source_key] != file[:destination]

          resp = s3_client.copy_object({
                                           bucket: s3_info[:aws_bucket_name],
                                           copy_source: s3_info[:aws_bucket_name] + '/' + file[:source_key],
                                           key: file[:destination]
                                       })

          if delete_source

            resp = s3_client.delete_object({
                                               bucket: s3_info[:aws_bucket_name],
                                               key: file[:source_key]
                                           })

          end

          if file[:source_key].ends_with?('.json') == false and s3_bucket.object(file[:source_key] + '.json').exists?

            resp = s3_client.copy_object({
                                             bucket: s3_info[:aws_bucket_name],
                                             copy_source: s3_info[:aws_bucket_name] + '/' + file[:source_key] + '.json',
                                             key: file[:destination] + '.json'
                                         })

            SaveFileTypeForAnalyticsWorker.perform_async(s3_info, file[:destination], nil)

            if delete_source

              resp = s3_client.delete_object({
                                                 bucket: s3_info[:aws_bucket_name],
                                                 key: file[:source_key] + '.json'
                                             })

            end

          end

        end
      }

    rescue Aws::S3::Errors::ServiceError => ex
      return {error: "#{ex.class}: #{ex.message}"}
    end

  end


  def s3_put_file s3_info, key, body

    s3_client = get_s3_client(s3_info)

    resp = s3_client.put_object(bucket: s3_info[:aws_bucket_name], key: key, body: body)

  end

  def s3_file_download_url s3_info, key

    s3_resource = Aws::S3::Resource.new(
        access_key_id: s3_info[:aws_bucket_access_key_id],
        secret_access_key: s3_info[:aws_bucket_secret_access_key],
        region: s3_info[:aws_bucket_region])

    obj = s3_resource.bucket(s3_info[:aws_bucket_name]).object(key)

    return obj.presigned_url(:get, expires_in: 3600)

  end

  def s3_read_object s3_info, key


    s3_client = get_s3_client(s3_info)

    begin

      resp = s3_client.get_object(bucket: s3_info[:aws_bucket_name], key: key)

      return {error: nil, body: resp.body.read}

    rescue Aws::S3::Errors::ServiceError => ex
      return {error: "#{ex.class}: #{ex.message}"}
    end

  end


  def s3_exists? s3_info, key

    s3_bucket = get_s3_bucket(s3_info).object(key).exists?

  end


  def s3_move_file s3_info, old_key, new_key

    s3_client = get_s3_client(s3_info)

    s3_client.copy_object({
                              bucket: s3_info[:aws_bucket_name],
                              copy_source: s3_info[:aws_bucket_name] + '/' + old_key,
                              key: new_key
                          })

    if (old_key != new_key)
      s3_client.delete_object({
                                  bucket: s3_info[:aws_bucket_name],
                                  key: old_key
                              })
    end
  end


  private

  def get_s3_client s3_info

    if Rails.configuration.aws_endpoint.nil?
      Aws::S3::Client.new(
          access_key_id: s3_info[:aws_bucket_access_key_id],
          secret_access_key: s3_info[:aws_bucket_secret_access_key],
          region: s3_info[:aws_bucket_region],
          http_proxy: Rails.configuration.http_proxy) #INT ENV
    else #fake S3
      Aws::S3::Client.new(
          access_key_id: s3_info[:aws_bucket_access_key_id],
          secret_access_key: s3_info[:aws_bucket_secret_access_key],
          region: s3_info[:aws_bucket_region],
          endpoint: Rails.configuration.aws_endpoint,
          force_path_style: true,
          ssl_verify_peer: false)
    end

  end

  def get_s3_bucket s3_info

    # if Rails.configuration.aws_endpoint.nil?
    #   Aws::S3::Resource.new(
    #       access_key_id: s3_info[:aws_bucket_access_key_id],
    #       secret_access_key: s3_info[:aws_bucket_secret_access_key],
    #       region: s3_info[:aws_bucket_region])
    #       .bucket(s3_info[:aws_bucket_name])
    # else #fake S3
    Aws::S3::Resource.new(
        client: get_s3_client(s3_info))
        .bucket(s3_info[:aws_bucket_name])
    # end

  end

end
