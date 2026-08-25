export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.15"
  }
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          extensions?: Json
          operationName?: string
          query?: string
          variables?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      external_identifiers: {
        Row: {
          created_at: string
          external_type: string
          external_value: string
          id: string
          is_primary: boolean
          organisation_id: string | null
          organisation_unit_id: string | null
          organisation_unit_organisation_id: string | null
          portfolio_id: string | null
          property_id: string | null
          service_location_id: string | null
          service_location_site_id: string | null
          site_area_id: string | null
          site_area_site_id: string | null
          site_id: string | null
          source_system: string
          tenant_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          external_type: string
          external_value: string
          id?: string
          is_primary?: boolean
          organisation_id?: string | null
          organisation_unit_id?: string | null
          organisation_unit_organisation_id?: string | null
          portfolio_id?: string | null
          property_id?: string | null
          service_location_id?: string | null
          service_location_site_id?: string | null
          site_area_id?: string | null
          site_area_site_id?: string | null
          site_id?: string | null
          source_system: string
          tenant_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          external_type?: string
          external_value?: string
          id?: string
          is_primary?: boolean
          organisation_id?: string | null
          organisation_unit_id?: string | null
          organisation_unit_organisation_id?: string | null
          portfolio_id?: string | null
          property_id?: string | null
          service_location_id?: string | null
          service_location_site_id?: string | null
          site_area_id?: string | null
          site_area_site_id?: string | null
          site_id?: string | null
          source_system?: string
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "external_identifiers_org_unit_fk"
            columns: [
              "tenant_id",
              "organisation_unit_organisation_id",
              "organisation_unit_id",
            ]
            isOneToOne: false
            referencedRelation: "organisation_units"
            referencedColumns: ["tenant_id", "organisation_id", "id"]
          },
          {
            foreignKeyName: "external_identifiers_organisation_fk"
            columns: ["tenant_id", "organisation_id"]
            isOneToOne: false
            referencedRelation: "organisations"
            referencedColumns: ["tenant_id", "id"]
          },
          {
            foreignKeyName: "external_identifiers_portfolio_fk"
            columns: ["tenant_id", "portfolio_id"]
            isOneToOne: false
            referencedRelation: "portfolios"
            referencedColumns: ["tenant_id", "id"]
          },
          {
            foreignKeyName: "external_identifiers_property_fk"
            columns: ["tenant_id", "property_id"]
            isOneToOne: false
            referencedRelation: "properties"
            referencedColumns: ["tenant_id", "id"]
          },
          {
            foreignKeyName: "external_identifiers_service_location_fk"
            columns: [
              "tenant_id",
              "service_location_site_id",
              "service_location_id",
            ]
            isOneToOne: false
            referencedRelation: "service_locations"
            referencedColumns: ["tenant_id", "site_id", "id"]
          },
          {
            foreignKeyName: "external_identifiers_site_area_fk"
            columns: ["tenant_id", "site_area_site_id", "site_area_id"]
            isOneToOne: false
            referencedRelation: "site_areas"
            referencedColumns: ["tenant_id", "site_id", "id"]
          },
          {
            foreignKeyName: "external_identifiers_site_fk"
            columns: ["tenant_id", "site_id"]
            isOneToOne: false
            referencedRelation: "sites"
            referencedColumns: ["tenant_id", "id"]
          },
          {
            foreignKeyName: "external_identifiers_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      organisation_relationship_types: {
        Row: {
          code: string
          created_at: string
          description: string | null
          id: string
          is_active: boolean
          name: string
          sort_order: number
          updated_at: string
        }
        Insert: {
          code: string
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          name: string
          sort_order?: number
          updated_at?: string
        }
        Update: {
          code?: string
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          name?: string
          sort_order?: number
          updated_at?: string
        }
        Relationships: []
      }
      organisation_relationships: {
        Row: {
          created_at: string
          effective_from: string
          effective_until: string | null
          id: string
          relationship_type_id: string
          source_organisation_id: string
          status: string
          target_organisation_id: string
          tenant_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          effective_from?: string
          effective_until?: string | null
          id?: string
          relationship_type_id: string
          source_organisation_id: string
          status?: string
          target_organisation_id: string
          tenant_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          effective_from?: string
          effective_until?: string | null
          id?: string
          relationship_type_id?: string
          source_organisation_id?: string
          status?: string
          target_organisation_id?: string
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "organisation_relationships_relationship_type_id_fkey"
            columns: ["relationship_type_id"]
            isOneToOne: false
            referencedRelation: "organisation_relationship_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "organisation_relationships_source_fk"
            columns: ["tenant_id", "source_organisation_id"]
            isOneToOne: false
            referencedRelation: "organisations"
            referencedColumns: ["tenant_id", "id"]
          },
          {
            foreignKeyName: "organisation_relationships_target_fk"
            columns: ["tenant_id", "target_organisation_id"]
            isOneToOne: false
            referencedRelation: "organisations"
            referencedColumns: ["tenant_id", "id"]
          },
          {
            foreignKeyName: "organisation_relationships_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      organisation_resource_assignments: {
        Row: {
          created_at: string
          effective_from: string
          effective_until: string | null
          id: string
          organisation_id: string
          property_id: string | null
          role_type_id: string
          service_location_id: string | null
          service_location_site_id: string | null
          site_area_id: string | null
          site_area_site_id: string | null
          site_id: string | null
          status: string
          tenant_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          effective_from?: string
          effective_until?: string | null
          id?: string
          organisation_id: string
          property_id?: string | null
          role_type_id: string
          service_location_id?: string | null
          service_location_site_id?: string | null
          site_area_id?: string | null
          site_area_site_id?: string | null
          site_id?: string | null
          status?: string
          tenant_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          effective_from?: string
          effective_until?: string | null
          id?: string
          organisation_id?: string
          property_id?: string | null
          role_type_id?: string
          service_location_id?: string | null
          service_location_site_id?: string | null
          site_area_id?: string | null
          site_area_site_id?: string | null
          site_id?: string | null
          status?: string
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "ora_organisation_fk"
            columns: ["tenant_id", "organisation_id"]
            isOneToOne: false
            referencedRelation: "organisations"
            referencedColumns: ["tenant_id", "id"]
          },
          {
            foreignKeyName: "ora_property_fk"
            columns: ["tenant_id", "property_id"]
            isOneToOne: false
            referencedRelation: "properties"
            referencedColumns: ["tenant_id", "id"]
          },
          {
            foreignKeyName: "ora_service_location_fk"
            columns: [
              "tenant_id",
              "service_location_site_id",
              "service_location_id",
            ]
            isOneToOne: false
            referencedRelation: "service_locations"
            referencedColumns: ["tenant_id", "site_id", "id"]
          },
          {
            foreignKeyName: "ora_site_area_fk"
            columns: ["tenant_id", "site_area_site_id", "site_area_id"]
            isOneToOne: false
            referencedRelation: "site_areas"
            referencedColumns: ["tenant_id", "site_id", "id"]
          },
          {
            foreignKeyName: "ora_site_fk"
            columns: ["tenant_id", "site_id"]
            isOneToOne: false
            referencedRelation: "sites"
            referencedColumns: ["tenant_id", "id"]
          },
          {
            foreignKeyName: "organisation_resource_assignments_role_type_id_fkey"
            columns: ["role_type_id"]
            isOneToOne: false
            referencedRelation: "organisation_resource_role_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "organisation_resource_assignments_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      organisation_resource_role_types: {
        Row: {
          code: string
          created_at: string
          description: string | null
          id: string
          is_active: boolean
          name: string
          sort_order: number
          updated_at: string
        }
        Insert: {
          code: string
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          name: string
          sort_order?: number
          updated_at?: string
        }
        Update: {
          code?: string
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          name?: string
          sort_order?: number
          updated_at?: string
        }
        Relationships: []
      }
      organisation_types: {
        Row: {
          code: string
          created_at: string
          description: string | null
          id: string
          is_active: boolean
          name: string
          sort_order: number
          updated_at: string
        }
        Insert: {
          code: string
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          name: string
          sort_order?: number
          updated_at?: string
        }
        Update: {
          code?: string
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          name?: string
          sort_order?: number
          updated_at?: string
        }
        Relationships: []
      }
      organisation_unit_types: {
        Row: {
          code: string
          created_at: string
          description: string | null
          id: string
          is_active: boolean
          name: string
          sort_order: number
          updated_at: string
        }
        Insert: {
          code: string
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          name: string
          sort_order?: number
          updated_at?: string
        }
        Update: {
          code?: string
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          name?: string
          sort_order?: number
          updated_at?: string
        }
        Relationships: []
      }
      organisation_units: {
        Row: {
          code: string
          created_at: string
          id: string
          lifecycle_status: string
          name: string
          organisation_id: string
          organisation_unit_type_id: string
          parent_organisation_unit_id: string | null
          tenant_id: string
          updated_at: string
        }
        Insert: {
          code: string
          created_at?: string
          id?: string
          lifecycle_status?: string
          name: string
          organisation_id: string
          organisation_unit_type_id: string
          parent_organisation_unit_id?: string | null
          tenant_id: string
          updated_at?: string
        }
        Update: {
          code?: string
          created_at?: string
          id?: string
          lifecycle_status?: string
          name?: string
          organisation_id?: string
          organisation_unit_type_id?: string
          parent_organisation_unit_id?: string | null
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "organisation_units_organisation_fk"
            columns: ["tenant_id", "organisation_id"]
            isOneToOne: false
            referencedRelation: "organisations"
            referencedColumns: ["tenant_id", "id"]
          },
          {
            foreignKeyName: "organisation_units_organisation_unit_type_id_fkey"
            columns: ["organisation_unit_type_id"]
            isOneToOne: false
            referencedRelation: "organisation_unit_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "organisation_units_parent_fk"
            columns: [
              "tenant_id",
              "organisation_id",
              "parent_organisation_unit_id",
            ]
            isOneToOne: false
            referencedRelation: "organisation_units"
            referencedColumns: ["tenant_id", "organisation_id", "id"]
          },
          {
            foreignKeyName: "organisation_units_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      organisations: {
        Row: {
          code: string
          country_of_registration_code: string | null
          created_at: string
          id: string
          lifecycle_status: string
          name: string
          organisation_type_id: string
          parent_organisation_id: string | null
          tenant_id: string
          updated_at: string
        }
        Insert: {
          code: string
          country_of_registration_code?: string | null
          created_at?: string
          id?: string
          lifecycle_status?: string
          name: string
          organisation_type_id: string
          parent_organisation_id?: string | null
          tenant_id: string
          updated_at?: string
        }
        Update: {
          code?: string
          country_of_registration_code?: string | null
          created_at?: string
          id?: string
          lifecycle_status?: string
          name?: string
          organisation_type_id?: string
          parent_organisation_id?: string | null
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "organisations_organisation_type_id_fkey"
            columns: ["organisation_type_id"]
            isOneToOne: false
            referencedRelation: "organisation_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "organisations_parent_fk"
            columns: ["tenant_id", "parent_organisation_id"]
            isOneToOne: false
            referencedRelation: "organisations"
            referencedColumns: ["tenant_id", "id"]
          },
          {
            foreignKeyName: "organisations_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      portfolio_members: {
        Row: {
          created_at: string
          effective_from: string
          effective_until: string | null
          id: string
          organisation_id: string | null
          organisation_unit_id: string | null
          organisation_unit_organisation_id: string | null
          portfolio_id: string
          property_id: string | null
          service_location_id: string | null
          service_location_site_id: string | null
          site_area_id: string | null
          site_area_site_id: string | null
          site_id: string | null
          tenant_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          effective_from?: string
          effective_until?: string | null
          id?: string
          organisation_id?: string | null
          organisation_unit_id?: string | null
          organisation_unit_organisation_id?: string | null
          portfolio_id: string
          property_id?: string | null
          service_location_id?: string | null
          service_location_site_id?: string | null
          site_area_id?: string | null
          site_area_site_id?: string | null
          site_id?: string | null
          tenant_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          effective_from?: string
          effective_until?: string | null
          id?: string
          organisation_id?: string | null
          organisation_unit_id?: string | null
          organisation_unit_organisation_id?: string | null
          portfolio_id?: string
          property_id?: string | null
          service_location_id?: string | null
          service_location_site_id?: string | null
          site_area_id?: string | null
          site_area_site_id?: string | null
          site_id?: string | null
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "portfolio_members_org_unit_fk"
            columns: [
              "tenant_id",
              "organisation_unit_organisation_id",
              "organisation_unit_id",
            ]
            isOneToOne: false
            referencedRelation: "organisation_units"
            referencedColumns: ["tenant_id", "organisation_id", "id"]
          },
          {
            foreignKeyName: "portfolio_members_organisation_fk"
            columns: ["tenant_id", "organisation_id"]
            isOneToOne: false
            referencedRelation: "organisations"
            referencedColumns: ["tenant_id", "id"]
          },
          {
            foreignKeyName: "portfolio_members_portfolio_fk"
            columns: ["tenant_id", "portfolio_id"]
            isOneToOne: false
            referencedRelation: "portfolios"
            referencedColumns: ["tenant_id", "id"]
          },
          {
            foreignKeyName: "portfolio_members_property_fk"
            columns: ["tenant_id", "property_id"]
            isOneToOne: false
            referencedRelation: "properties"
            referencedColumns: ["tenant_id", "id"]
          },
          {
            foreignKeyName: "portfolio_members_service_location_fk"
            columns: [
              "tenant_id",
              "service_location_site_id",
              "service_location_id",
            ]
            isOneToOne: false
            referencedRelation: "service_locations"
            referencedColumns: ["tenant_id", "site_id", "id"]
          },
          {
            foreignKeyName: "portfolio_members_site_area_fk"
            columns: ["tenant_id", "site_area_site_id", "site_area_id"]
            isOneToOne: false
            referencedRelation: "site_areas"
            referencedColumns: ["tenant_id", "site_id", "id"]
          },
          {
            foreignKeyName: "portfolio_members_site_fk"
            columns: ["tenant_id", "site_id"]
            isOneToOne: false
            referencedRelation: "sites"
            referencedColumns: ["tenant_id", "id"]
          },
          {
            foreignKeyName: "portfolio_members_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      portfolios: {
        Row: {
          code: string
          created_at: string
          description: string | null
          id: string
          lifecycle_status: string
          name: string
          tenant_id: string
          updated_at: string
        }
        Insert: {
          code: string
          created_at?: string
          description?: string | null
          id?: string
          lifecycle_status?: string
          name: string
          tenant_id: string
          updated_at?: string
        }
        Update: {
          code?: string
          created_at?: string
          description?: string | null
          id?: string
          lifecycle_status?: string
          name?: string
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "portfolios_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      properties: {
        Row: {
          address_line_1: string | null
          address_line_2: string | null
          administrative_area: string | null
          code: string
          country_code: string | null
          created_at: string
          id: string
          latitude: number | null
          lifecycle_status: string
          locality: string | null
          longitude: number | null
          name: string
          postal_code: string | null
          property_type_id: string
          tenant_id: string
          updated_at: string
        }
        Insert: {
          address_line_1?: string | null
          address_line_2?: string | null
          administrative_area?: string | null
          code: string
          country_code?: string | null
          created_at?: string
          id?: string
          latitude?: number | null
          lifecycle_status?: string
          locality?: string | null
          longitude?: number | null
          name: string
          postal_code?: string | null
          property_type_id: string
          tenant_id: string
          updated_at?: string
        }
        Update: {
          address_line_1?: string | null
          address_line_2?: string | null
          administrative_area?: string | null
          code?: string
          country_code?: string | null
          created_at?: string
          id?: string
          latitude?: number | null
          lifecycle_status?: string
          locality?: string | null
          longitude?: number | null
          name?: string
          postal_code?: string | null
          property_type_id?: string
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "properties_property_type_id_fkey"
            columns: ["property_type_id"]
            isOneToOne: false
            referencedRelation: "property_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "properties_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      property_types: {
        Row: {
          code: string
          created_at: string
          description: string | null
          id: string
          is_active: boolean
          name: string
          sort_order: number
          updated_at: string
        }
        Insert: {
          code: string
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          name: string
          sort_order?: number
          updated_at?: string
        }
        Update: {
          code?: string
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          name?: string
          sort_order?: number
          updated_at?: string
        }
        Relationships: []
      }
      service_location_types: {
        Row: {
          code: string
          created_at: string
          description: string | null
          id: string
          is_active: boolean
          name: string
          sort_order: number
          updated_at: string
        }
        Insert: {
          code: string
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          name: string
          sort_order?: number
          updated_at?: string
        }
        Update: {
          code?: string
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          name?: string
          sort_order?: number
          updated_at?: string
        }
        Relationships: []
      }
      service_locations: {
        Row: {
          code: string
          created_at: string
          id: string
          is_consumer_facing: boolean
          lifecycle_status: string
          name: string
          parent_service_location_id: string | null
          service_location_type_id: string
          site_area_id: string | null
          site_id: string
          tenant_id: string
          updated_at: string
        }
        Insert: {
          code: string
          created_at?: string
          id?: string
          is_consumer_facing?: boolean
          lifecycle_status?: string
          name: string
          parent_service_location_id?: string | null
          service_location_type_id: string
          site_area_id?: string | null
          site_id: string
          tenant_id: string
          updated_at?: string
        }
        Update: {
          code?: string
          created_at?: string
          id?: string
          is_consumer_facing?: boolean
          lifecycle_status?: string
          name?: string
          parent_service_location_id?: string | null
          service_location_type_id?: string
          site_area_id?: string | null
          site_id?: string
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "service_locations_parent_fk"
            columns: ["tenant_id", "site_id", "parent_service_location_id"]
            isOneToOne: false
            referencedRelation: "service_locations"
            referencedColumns: ["tenant_id", "site_id", "id"]
          },
          {
            foreignKeyName: "service_locations_service_location_type_id_fkey"
            columns: ["service_location_type_id"]
            isOneToOne: false
            referencedRelation: "service_location_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_locations_site_area_fk"
            columns: ["tenant_id", "site_id", "site_area_id"]
            isOneToOne: false
            referencedRelation: "site_areas"
            referencedColumns: ["tenant_id", "site_id", "id"]
          },
          {
            foreignKeyName: "service_locations_site_fk"
            columns: ["tenant_id", "site_id"]
            isOneToOne: false
            referencedRelation: "sites"
            referencedColumns: ["tenant_id", "id"]
          },
          {
            foreignKeyName: "service_locations_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      site_area_types: {
        Row: {
          code: string
          created_at: string
          description: string | null
          id: string
          is_active: boolean
          name: string
          sort_order: number
          updated_at: string
        }
        Insert: {
          code: string
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          name: string
          sort_order?: number
          updated_at?: string
        }
        Update: {
          code?: string
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          name?: string
          sort_order?: number
          updated_at?: string
        }
        Relationships: []
      }
      site_areas: {
        Row: {
          code: string
          created_at: string
          id: string
          lifecycle_status: string
          name: string
          parent_site_area_id: string | null
          site_area_type_id: string
          site_id: string
          tenant_id: string
          updated_at: string
        }
        Insert: {
          code: string
          created_at?: string
          id?: string
          lifecycle_status?: string
          name: string
          parent_site_area_id?: string | null
          site_area_type_id: string
          site_id: string
          tenant_id: string
          updated_at?: string
        }
        Update: {
          code?: string
          created_at?: string
          id?: string
          lifecycle_status?: string
          name?: string
          parent_site_area_id?: string | null
          site_area_type_id?: string
          site_id?: string
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "site_areas_parent_fk"
            columns: ["tenant_id", "site_id", "parent_site_area_id"]
            isOneToOne: false
            referencedRelation: "site_areas"
            referencedColumns: ["tenant_id", "site_id", "id"]
          },
          {
            foreignKeyName: "site_areas_site_area_type_id_fkey"
            columns: ["site_area_type_id"]
            isOneToOne: false
            referencedRelation: "site_area_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "site_areas_site_fk"
            columns: ["tenant_id", "site_id"]
            isOneToOne: false
            referencedRelation: "sites"
            referencedColumns: ["tenant_id", "id"]
          },
          {
            foreignKeyName: "site_areas_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      site_types: {
        Row: {
          code: string
          created_at: string
          description: string | null
          id: string
          is_active: boolean
          name: string
          sort_order: number
          updated_at: string
        }
        Insert: {
          code: string
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          name: string
          sort_order?: number
          updated_at?: string
        }
        Update: {
          code?: string
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          name?: string
          sort_order?: number
          updated_at?: string
        }
        Relationships: []
      }
      sites: {
        Row: {
          address_line_1: string | null
          address_line_2: string | null
          administrative_area: string | null
          code: string
          country_code: string | null
          created_at: string
          currency_code: string | null
          id: string
          latitude: number | null
          lifecycle_status: string
          locale: string | null
          locality: string | null
          longitude: number | null
          mode: string
          name: string
          postal_code: string | null
          property_id: string | null
          site_type_id: string
          tenant_id: string
          timezone: string
          updated_at: string
        }
        Insert: {
          address_line_1?: string | null
          address_line_2?: string | null
          administrative_area?: string | null
          code: string
          country_code?: string | null
          created_at?: string
          currency_code?: string | null
          id?: string
          latitude?: number | null
          lifecycle_status?: string
          locale?: string | null
          locality?: string | null
          longitude?: number | null
          mode?: string
          name: string
          postal_code?: string | null
          property_id?: string | null
          site_type_id: string
          tenant_id: string
          timezone: string
          updated_at?: string
        }
        Update: {
          address_line_1?: string | null
          address_line_2?: string | null
          administrative_area?: string | null
          code?: string
          country_code?: string | null
          created_at?: string
          currency_code?: string | null
          id?: string
          latitude?: number | null
          lifecycle_status?: string
          locale?: string | null
          locality?: string | null
          longitude?: number | null
          mode?: string
          name?: string
          postal_code?: string | null
          property_id?: string | null
          site_type_id?: string
          tenant_id?: string
          timezone?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "sites_property_fk"
            columns: ["tenant_id", "property_id"]
            isOneToOne: false
            referencedRelation: "properties"
            referencedColumns: ["tenant_id", "id"]
          },
          {
            foreignKeyName: "sites_site_type_id_fkey"
            columns: ["site_type_id"]
            isOneToOne: false
            referencedRelation: "site_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sites_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      tenants: {
        Row: {
          created_at: string
          default_currency_code: string | null
          default_locale: string | null
          default_timezone: string | null
          id: string
          lifecycle_status: string
          name: string
          slug: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          default_currency_code?: string | null
          default_locale?: string | null
          default_timezone?: string | null
          id?: string
          lifecycle_status?: string
          name: string
          slug: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          default_currency_code?: string | null
          default_locale?: string | null
          default_timezone?: string | null
          id?: string
          lifecycle_status?: string
          name?: string
          slug?: string
          updated_at?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {},
  },
} as const
